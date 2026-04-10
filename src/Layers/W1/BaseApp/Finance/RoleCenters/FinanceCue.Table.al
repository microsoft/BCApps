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
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

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
            ToolTip = 'Specifies the number of sales invoices where the customer is late with payment.';
            FieldClass = FlowField;
        }
        field(3; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Date Filter"),
                                                             Open = const(true)));
            Caption = 'Purchase Documents Due Today';
            ToolTip = 'Specifies the number of purchase invoices where you are late with payment.';
            FieldClass = FlowField;
        }
        field(4; "POs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         Status = filter("Pending Approval")));
            Caption = 'POs Pending Approval';
            ToolTip = 'Specifies the number of purchase orders that are pending approval.';
            FieldClass = FlowField;
        }
        field(5; "SOs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter("Pending Approval")));
            Caption = 'SOs Pending Approval';
            ToolTip = 'Specifies the number of sales orders that are pending approval.';
            FieldClass = FlowField;
        }
        field(6; "Approved Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Sales Orders';
            ToolTip = 'Specifies the number of approved sales orders.';
            FieldClass = FlowField;
        }
        field(7; "Approved Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Purchase Orders';
            ToolTip = 'Specifies the number of approved purchase orders.';
            FieldClass = FlowField;
        }
        field(8; "Vendors - Payment on Hold"; Integer)
        {
            CalcFormula = count(Vendor where(Blocked = filter(Payment)));
            Caption = 'Vendors - Payment on Hold';
            ToolTip = 'Specifies the number of vendor to whom your payment is on hold.';
            FieldClass = FlowField;
        }
        field(9; "Purchase Return Orders"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Return Order")));
            Caption = 'Purchase Return Orders';
            ToolTip = 'Specifies the number of purchase return orders that are displayed in the Finance Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(10; "Sales Return Orders - All"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const("Return Order")));
            Caption = 'Sales Return Orders - All';
            ToolTip = 'Specifies the number of sales return orders that are displayed in the Finance Cue on the Role Center. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(11; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            ToolTip = 'Specifies the number of customer that are blocked from further sales.';
            FieldClass = FlowField;
        }
        field(16; "Overdue Purchase Documents"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Overdue Date Filter"),
                                                             Open = const(true)));
            Caption = 'Overdue Purchase Documents';
            ToolTip = 'Specifies the number of purchase invoices where your payment is late.';
            FieldClass = FlowField;
        }
        field(17; "Purchase Discounts Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Pmt. Discount Date" = field("Due Next Week Filter"),
                                                             Open = const(true)));
            Caption = 'Purchase Discounts Next Week';
            ToolTip = 'Specifies the number of purchase discounts that are available next week, for example, because the discount expires after next week.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Next Week Filter"),
                                                             Open = const(true)));
            Caption = 'Purch. Invoices Due Next Week';
            ToolTip = 'Specifies the number of payments to vendors that are due next week.';
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
            CalcFormula = count("Incoming Document" where(Status = const(New), Processed = const(false)));
            Caption = 'New Incoming Documents';
            ToolTip = 'Specifies the number of new incoming documents in the company. The documents are filtered by today''s date.';
            FieldClass = FlowField;
        }
        field(23; "Approved Incoming Documents"; Integer)
        {
            CalcFormula = count("Incoming Document" where(Status = const(Released)));
            Caption = 'Approved Incoming Documents';
            ToolTip = 'Specifies the number of approved incoming documents in the company. The documents are filtered by today''s date.';
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
            ToolTip = 'Specifies that incoming document records that have been created by the OCR service.';
            FieldClass = FlowField;
        }
        field(29; "Non-Applied Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Non-Applied Payments';
            ToolTip = 'Specifies a window to reconcile unpaid documents automatically with their related bank transactions by importing a bank statement feed or file. In the payment reconciliation journal, incoming or outgoing payments on your bank are automatically, or semi-automatically, applied to their related open customer or vendor ledger entries. Any open bank account ledger entries related to the applied customer or vendor ledger entries will be closed when you choose the Post Payments and Reconcile Bank Account action. This means that the bank account is automatically reconciled for payments that you post with the journal.';
            FieldClass = FlowField;
        }
        field(30; "Cash Accounts Balance"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Cash Accounts Balance';
            ToolTip = 'Specifies the sum of the accounts that have the cash account category.';
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
            ToolTip = 'Specifies the number of invoices from your vendors that have not been paid yet.';
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
            ToolTip = 'Specifies the number of reminders that have been created but have not been issued yet.';
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
            ToolTip = 'Specifies the number of reminders that are issued and still not paid.';
        }
        field(40; "Reminders not Send"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Issued Reminder Header" where("Sent For Current Level" = const(false), Canceled = const(false)));
            Caption = 'Reminders not Send';
            ToolTip = 'Specifies the number of reminders that have not been sent yet for the current level.';
        }
        field(41; "Active Reminder Automation"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Reminder Action Group" where(Blocked = const(false)));
            Caption = 'Active Reminder Automation';
            ToolTip = 'Specifies the number of automations configured for reminders.';
        }
        field(42; "Reminder Automation Failures"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Reminder Automation Error" where(Dismissed = const(false)));
            Caption = 'Reminder Automation Failures';
            ToolTip = 'Specifies the number of failures that occured for the existing reminder automations.';
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
