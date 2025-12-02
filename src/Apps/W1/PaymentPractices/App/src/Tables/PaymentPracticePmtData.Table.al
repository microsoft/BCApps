// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

table 689 "Payment Practice Pmt. Data"
{
    Caption = 'Payment Practice Payment Data';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Integer)
        {
            Caption = 'Header No.';
            TableRelation = "Payment Practice Header"."No.";
            ToolTip = 'Specifies the number of the payment practice header.';
        }
        field(2; "Source Type"; Enum "Paym. Prac. Header Type")
        {
            Caption = 'Source Type';
            ToolTip = 'Specifies the source type of the payment application (Vendor or Customer).';
        }
        field(3; "Invoice Entry No."; Integer)
        {
            Caption = 'Invoice Entry No.';
            ToolTip = 'Specifies the entry number of the invoice ledger entry.';
        }
        field(4; "Payment Entry No."; Integer)
        {
            Caption = 'Payment Entry No.';
            ToolTip = 'Specifies the entry number of the payment ledger entry.';
        }
        field(10; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            ToolTip = 'Specifies the vendor or customer number.';
        }
        field(11; "Invoice Doc. No."; Code[20])
        {
            Caption = 'Invoice Document No.';
            ToolTip = 'Specifies the document number of the invoice.';
        }
        field(12; "Payment Doc. No."; Code[20])
        {
            Caption = 'Payment Document No.';
            ToolTip = 'Specifies the document number of the payment.';
        }
        field(20; "Invoice Due Date"; Date)
        {
            Caption = 'Invoice Due Date';
            ToolTip = 'Specifies the due date of the invoice.';
        }
        field(21; "Payment Posting Date"; Date)
        {
            Caption = 'Payment Posting Date';
            ToolTip = 'Specifies the posting date of the payment.';
        }
        field(22; "SCF Payment Date"; Date)
        {
            Caption = 'SCF Payment Date';
            ToolTip = 'Specifies the date when the finance provider paid the supplier under a Supply Chain Finance arrangement.';
        }
        field(28; "Invoice Total Amount"; Decimal)
        {
            Caption = 'Invoice Total Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the total amount of the invoice.';
        }
        field(29; "Payment Total Amount"; Decimal)
        {
            Caption = 'Payment Total Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the total amount of the payment.';
        }
        field(30; "Applied Amount"; Decimal)
        {
            Caption = 'Applied Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the amount applied from the payment to the invoice.';
        }
        field(31; "Is Late"; Boolean)
        {
            Caption = 'Is Late';
            ToolTip = 'Specifies if the payment was made after the invoice due date.';
        }
        field(32; "Late Due to Dispute"; Boolean)
        {
            Caption = 'Late Due to Dispute';
            ToolTip = 'Specifies if the late payment was due to a dispute.';
        }
    }

    keys
    {
        key(Key1; "Header No.", "Source Type", "Invoice Entry No.", "Payment Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Header No.", "Payment Posting Date", "Is Late") { SumIndexFields = "Applied Amount"; }
    }

    procedure CopyFromVendorApplication(InvoiceVendorLedgerEntry: Record "Vendor Ledger Entry"; PaymentVendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedAmountLCY: Decimal; HeaderNo: Integer)
    var
        EffectivePaymentDate: Date;
    begin
        "Header No." := HeaderNo;
        "Source Type" := "Paym. Prac. Header Type"::Vendor;
        "Invoice Entry No." := InvoiceVendorLedgerEntry."Entry No.";
        "Payment Entry No." := PaymentVendorLedgerEntry."Entry No.";
        "CV No." := InvoiceVendorLedgerEntry."Vendor No.";
        "Invoice Doc. No." := InvoiceVendorLedgerEntry."Document No.";
        "Payment Doc. No." := PaymentVendorLedgerEntry."Document No.";
        "Invoice Due Date" := InvoiceVendorLedgerEntry."Due Date";
        "Payment Posting Date" := PaymentVendorLedgerEntry."Posting Date";
        "SCF Payment Date" := PaymentVendorLedgerEntry."SCF Payment Date";
        InvoiceVendorLedgerEntry.CalcFields("Amount (LCY)");
        PaymentVendorLedgerEntry.CalcFields("Amount (LCY)");
        "Invoice Total Amount" := Abs(InvoiceVendorLedgerEntry."Amount (LCY)");
        "Payment Total Amount" := Abs(PaymentVendorLedgerEntry."Amount (LCY)");
        "Applied Amount" := Abs(AppliedAmountLCY);
        EffectivePaymentDate := GetEffectivePaymentDate();
        "Is Late" := EffectivePaymentDate > "Invoice Due Date";
        if "Is Late" then
            "Late Due to Dispute" := InvoiceVendorLedgerEntry."Overdue Due to Dispute";
    end;

    procedure CopyFromCustomerApplication(InvoiceCustLedgerEntry: Record "Cust. Ledger Entry"; PaymentCustLedgerEntry: Record "Cust. Ledger Entry"; AppliedAmountLCY: Decimal; HeaderNo: Integer)
    begin
        "Header No." := HeaderNo;
        "Source Type" := "Paym. Prac. Header Type"::Customer;
        "Invoice Entry No." := InvoiceCustLedgerEntry."Entry No.";
        "Payment Entry No." := PaymentCustLedgerEntry."Entry No.";
        "CV No." := InvoiceCustLedgerEntry."Customer No.";
        "Invoice Doc. No." := InvoiceCustLedgerEntry."Document No.";
        "Payment Doc. No." := PaymentCustLedgerEntry."Document No.";
        "Invoice Due Date" := InvoiceCustLedgerEntry."Due Date";
        "Payment Posting Date" := PaymentCustLedgerEntry."Posting Date";
        InvoiceCustLedgerEntry.CalcFields("Amount (LCY)");
        PaymentCustLedgerEntry.CalcFields("Amount (LCY)");
        "Invoice Total Amount" := Abs(InvoiceCustLedgerEntry."Amount (LCY)");
        "Payment Total Amount" := Abs(PaymentCustLedgerEntry."Amount (LCY)");
        "Applied Amount" := Abs(AppliedAmountLCY);
        "Is Late" := "Payment Posting Date" > "Invoice Due Date";
        if "Is Late" then
            "Late Due to Dispute" := InvoiceCustLedgerEntry."Overdue Due to Dispute";
    end;

    local procedure GetEffectivePaymentDate(): Date
    begin
        if "SCF Payment Date" <> 0D then
            exit("SCF Payment Date");
        exit("Payment Posting Date");
    end;
}
