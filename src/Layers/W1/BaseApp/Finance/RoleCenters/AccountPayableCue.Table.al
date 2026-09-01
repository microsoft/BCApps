// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using System.Environment;
using System.Reflection;

table 9046 "Account Payable Cue"
{
    Caption = 'Account Payable Cue';
    DataClassification = CustomerContent;
    ReplicateData = false;

    InherentEntitlements = X;
    InherentPermissions = X;


    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(20; "Purchase This Month"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            CalcFormula = - sum("Vendor Ledger Entry"."Purchase (LCY)" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                                            "Posting Date" = field("Posting Date Filter"),
                                                                            Open = const(true)));
            Caption = 'Purchase This Month';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total amount of purchase invoices for the current month.';
        }
        field(21; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Overdue Purchase Documents"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Purchase Documents';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase invoices where your payment is late.';
        }
        field(23; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(24; "POs Pending Approval"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                        Status = filter("Pending Approval")));
            Caption = 'POs Pending Approval';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase orders that are pending approval.';
        }
        field(25; "Approved Purchase Orders"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                        Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase orders that are approved.';
        }
        field(26; "Purchase Quotes"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Quote),
                                                        Status = filter(Open)));
            Caption = 'Purchase Quotes';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase quotes.';
        }
        field(27; "Purchase Orders"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                        Status = filter(Open)));
            Caption = 'Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase orders.';
        }
        field(28; "Ongoing Purchase Invoices"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Invoice)));
            Caption = 'Ongoing Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of ongoing purchase invoices.';
        }
        field(29; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Due Next Week Filter"),
                                                            Open = const(true)));
            Caption = 'Purch. Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase invoices that are due next week.';
        }
        field(30; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Posted Purch. Inv. This Month"; Integer)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            CalcFormula = count("Purch. Inv. Header" where("Posting Date" = field("Posting Date Filter")));
            Caption = 'Posted Purch. Inv. This Month';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of posted purchase invoices for the current month.';
        }
        field(32; "Posted Purch. Cr. Memo TM"; Integer)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            CalcFormula = count("Purch. Cr. Memo Hdr." where("Posting Date" = field("Posting Date Filter")));
            Caption = 'Posted Purch. Cr. Memo This Month';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of posted purchase credit memos for the current month.';
        }
        field(33; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Purchase Documents Due Today';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase invoices that are due today.';
        }
        field(34; "Purch. Documents Due Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Due Next Week Filter"),
                                                            Open = const(true)));
            Caption = 'Purchase Documents Due Next Week';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase invoices that are due next week.';
        }
        field(35; "Purchase Discounts Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Pmt. Discount Date" = field("Due Next Week Filter"),
                                                            Open = const(true)));
            Caption = 'Purchase Discounts Next Week';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of purchase invoices that are due next week and have a payment discount.';
        }
        field(36; "Unprocessed Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Unprocessed Payments';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of unprocessed payments.';
        }
        field(37; "Outstanding Vendor Invoices"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice),
                                                            "Remaining Amount" = filter(< 0),
                                                            "Applies-to ID" = filter('')));
            Caption = 'Outstanding Vendor Invoices';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of invoices from your vendors that have not been paid yet.';
        }
        field(110; "Last Date/Time Modified"; DateTime)
        {
            Caption = 'Last Date/Time Modified';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        DefaultWorkDate: Date;

    internal procedure GetAmountFormat(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetAmountFormatLCYWithUserLocale());
    end;

    internal procedure GetDefaultWorkDate(): Date
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        if this.DefaultWorkDate = 0D then
            this.DefaultWorkDate := LogInManagement.GetDefaultWorkDate();
        exit(this.DefaultWorkDate);
    end;
}
