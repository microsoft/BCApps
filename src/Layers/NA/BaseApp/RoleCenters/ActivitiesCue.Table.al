// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.EServices.EDocument;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Reflection;

table 1313 "Activities Cue"
{
    Caption = 'Activities Cue';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(3; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(4; "Ongoing Sales Invoices"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Invoice)));
            Caption = 'Ongoing Sales Invoices';
            FieldClass = FlowField;
        }
        field(5; "Ongoing Purchase Invoices"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Invoice)));
            Caption = 'Ongoing Purchase Invoices';
            FieldClass = FlowField;
        }
        field(6; "Sales This Month"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Sales This Month';
            DecimalPlaces = 0 : 0;
        }
        field(7; "Top 10 Customer Sales YTD"; Decimal)
        {
            AutoFormatExpression = '<Precision,1:1><Standard Format,9>%';
            AutoFormatType = 11;
            Caption = 'Top 10 Customer Sales YTD';
        }
        field(8; "Overdue Purch. Invoice Amount"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Overdue Purch. Invoice Amount';
            DecimalPlaces = 0 : 0;
        }
        field(9; "Overdue Sales Invoice Amount"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Overdue Sales Invoice Amount';
            DecimalPlaces = 0 : 0;
        }
        field(10; "Average Collection Days"; Decimal)
        {
            Caption = 'Average Collection Days';
            DecimalPlaces = 1 : 1;
        }
        field(11; "Ongoing Sales Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Quote)));
            Caption = 'Ongoing Sales Quotes';
            FieldClass = FlowField;
        }
        field(13; "Sales Inv. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Sales CrM. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = count("Sales Cr.Memo Header" where("Document Exchange Status" = filter("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
        }
        field(20; "My Incoming Documents"; Integer)
        {
            CalcFormula = count("Incoming Document" where(Processed = const(false)));
            Caption = 'My Incoming Documents';
            FieldClass = FlowField;
        }
        field(21; "Non-Applied Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(22; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Next Week Filter"),
                                                             Open = const(true)));
            Caption = 'Purch. Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Sales Invoices Due Next Week"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Due Next Week Filter"),
                                                            Open = const(true)));
            Caption = 'Sales Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Ongoing Sales Orders"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Order)));
            Caption = 'Ongoing Sales Orders';
            FieldClass = FlowField;
        }
        field(25; "Inc. Doc. Awaiting Verfication"; Integer)
        {
            CalcFormula = count("Incoming Document" where("OCR Status" = const("Awaiting Verification")));
            Caption = 'Inc. Doc. Awaiting Verification';
            FieldClass = FlowField;
        }
        field(26; "Purchase Orders"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order)));
            Caption = 'Purchase Orders';
            FieldClass = FlowField;
        }
        field(27; "Uninvoiced Bookings"; Integer)
        {
            Caption = 'Uninvoiced Bookings';
            Editable = false;
        }
        field(28; "IC Inbox Transactions"; Integer)
        {
            CalcFormula = count("IC Inbox Transaction");
            Caption = 'IC Inbox Transactions';
            FieldClass = FlowField;
        }
        field(29; "IC Outbox Transactions"; Integer)
        {
            CalcFormula = count("IC Outbox Transaction");
            Caption = 'IC Outbox Transactions';
            FieldClass = FlowField;
        }
        field(31; "Outstanding Vendor Invoices"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice),
                                                             Open = const(true)));
            Caption = 'Outstanding Vendor Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = count("CRM Integration Record" where(Skipped = const(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
        }
        field(33; "CDS Integration Errors"; Integer)
        {
            CalcFormula = count("Integration Synch. Job Errors");
            Caption = 'Dataverse Integration Errors';
            FieldClass = FlowField;
        }
        field(34; "S. Ord. - Reserved From Stock"; Integer)
        {
            Caption = 'Sales Orders - Completely Reserved from Stock';
        }
        field(110; "Last Date/Time Modified"; DateTime)
        {
            Caption = 'Last Date/Time Modified';
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

    procedure GetAmountFormat(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        AmountFormat: Text;
    begin
        AmountFormat := TypeHelper.GetAmountFormatLCYWithUserLocale().Trim();
        if AmountFormat = TypeHelper.GetDefaultAmountFormat() then
            exit('$' + TypeHelper.GetDefaultAmountFormat());

        exit(AmountFormat);
    end;
}

