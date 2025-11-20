// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Reminder;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

table 9054 "Finance Cue"
{
    Caption = 'Finance Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(3; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Date Filter"),
                                                             Open = const(true)));
            Caption = 'Purchase Documents Due Today';
            FieldClass = FlowField;
        }
        field(4; "POs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         Status = filter("Pending Approval")));
            Caption = 'POs Pending Approval';
            FieldClass = FlowField;
        }
        field(5; "SOs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter("Pending Approval")));
            Caption = 'SOs Pending Approval';
            FieldClass = FlowField;
        }
        field(6; "Approved Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Sales Orders';
            FieldClass = FlowField;
        }
        field(7; "Approved Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Purchase Orders';
            FieldClass = FlowField;
        }
        field(8; "Vendors - Payment on Hold"; Integer)
        {
            CalcFormula = count(Vendor where(Blocked = filter(Payment)));
            Caption = 'Vendors - Payment on Hold';
            FieldClass = FlowField;
        }
        field(9; "Purchase Return Orders"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Return Order")));
            Caption = 'Purchase Return Orders';
            FieldClass = FlowField;
        }
        field(10; "Sales Return Orders - All"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const("Return Order")));
            Caption = 'Sales Return Orders - All';
            FieldClass = FlowField;
        }
        field(11; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(16; "Overdue Purchase Documents"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Overdue Date Filter"),
                                                             Open = const(true)));
            Caption = 'Overdue Purchase Documents';
            FieldClass = FlowField;
        }
        field(17; "Purchase Discounts Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Pmt. Discount Date" = field("Due Next Week Filter"),
                                                             Open = const(true)));
            Caption = 'Purchase Discounts Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Next Week Filter"),
                                                             Open = const(true)));
            Caption = 'Purch. Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
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
        field(22; "New Incoming Documents"; Integer)
        {
            CalcFormula = count("Incoming Document" where(Status = const(New)));
            Caption = 'New Incoming Documents';
            FieldClass = FlowField;
        }
        field(23; "Approved Incoming Documents"; Integer)
        {
            CalcFormula = count("Incoming Document" where(Status = const(Released)));
            Caption = 'Approved Incoming Documents';
            FieldClass = FlowField;
        }
        field(24; "OCR Pending"; Integer)
        {
            CalcFormula = count("Incoming Document" where("OCR Status" = filter(Ready | Sent | "Awaiting Verification")));
            Caption = 'OCR Pending';
            FieldClass = FlowField;
        }
        field(25; "OCR Completed"; Integer)
        {
            CalcFormula = count("Incoming Document" where("OCR Status" = const(Success)));
            Caption = 'OCR Completed';
            FieldClass = FlowField;
        }
        field(29; "Non-Applied Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(30; "Cash Accounts Balance"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Cash Accounts Balance';
            FieldClass = Normal;
        }
        field(31; "Last Depreciated Posted Date"; Date)
        {
            CalcFormula = max("FA Ledger Entry"."FA Posting Date" where("FA Posting Type" = const(Depreciation)));
            Caption = 'Last Depreciated Posted Date';
            FieldClass = FlowField;
        }
        field(33; "Outstanding Vendor Invoices"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice),
                                                             "Remaining Amount" = filter(< 0),
                                                             "Applies-to ID" = filter('')));
            Caption = 'Outstanding Vendor Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "Total Overdue (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Total Overdue (LCY)';
            FieldClass = FlowField;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where(
                "Initial Entry Due Date" = field(upperlimit("Overdue Date Filter"))
            ));
        }
        field(35; "Total Outstanding (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Total Outstanding (LCY)';
            FieldClass = FlowField;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)");
        }
        field(36; "Non Issued Reminders"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Reminder Header" where("Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Non Issued Reminders';
        }
        field(37; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
            Caption = 'Date Filter';
        }
        field(38; "AR Accounts Balance"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'A/R Accounts Balance';
            FieldClass = Normal;
        }
        field(39; "Active Reminders"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Issued Reminder Header" where(Canceled = const(false)));
            Caption = 'Active Reminders';
        }
        field(40; "Reminders not Send"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Issued Reminder Header" where("Sent For Current Level" = const(false), Canceled = const(false)));
            Caption = 'Reminders not Send';
        }
        field(41; "Active Reminder Automation"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Reminder Action Group" where(Blocked = const(false)));
            Caption = 'Active Reminder Automation';
        }
        field(42; "Reminder Automation Failures"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Reminder Automation Error" where(Dismissed = const(false)));
            Caption = 'Reminder Automation Failures';
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

    local procedure GetAmountFormat(): Text
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        exit(ActivitiesCue.GetAmountFormat());
    end;
}
