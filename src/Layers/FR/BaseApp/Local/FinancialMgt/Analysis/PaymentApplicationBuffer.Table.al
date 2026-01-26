#if not CLEANSCHEMA26 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

table 10881 "Payment Application Buffer"
{
    Caption = 'Payment Application Buffer';
    ObsoleteReason = 'This table is obsolete. Replaced by W1 extension "Payment Practices".';
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Invoice Entry No."; Integer)
        {
            Caption = 'Invoice Entry No.';
        }
        field(2; "Pmt. Entry No."; Integer)
        {
            Caption = 'Pmt. Entry No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(6; "Pmt. Posting Date"; Date)
        {
            Caption = 'Pmt. Posting Date';
        }
        field(7; "Invoice Is Open"; Boolean)
        {
            Caption = 'Invoice Is Open';
        }
        field(10; "Invoice Doc. No."; Code[20])
        {
            Caption = 'Invoice Doc. No.';
        }
        field(11; "CV No."; Code[20])
        {
            Caption = 'CV No.';
        }
        field(12; "Inv. External Document No."; Code[35])
        {
            Caption = 'Inv. External Document No.';
        }
        field(13; "Pmt. Doc. No."; Code[20])
        {
            Caption = 'Pmt. Doc. No.';
        }
        field(20; "Entry Amount (LCY)"; Decimal)
        {
            Caption = 'Entry Amount (LCY)';
        }
        field(21; "Pmt. Amount (LCY)"; Decimal)
        {
            Caption = 'Pmt. Amount (LCY)';
        }
        field(22; "Remaining Amount (LCY)"; Decimal)
        {
            Caption = 'Remaining Amount (LCY)';
        }
        field(23; "Entry Amount Corrected (LCY)"; Decimal)
        {
            Caption = 'Entry Amount Corrected (LCY)';
        }
        field(30; "Days Since Due Date"; Integer)
        {
            Caption = 'Days Since Due Date';
        }
        field(31; "Pmt. Days Delayed"; Integer)
        {
            Caption = 'Pmt. Days Delayed';
        }
    }

    keys
    {
        key(Key1; "Invoice Entry No.", "Pmt. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure InsertVendorInvoice(VendorLedgerEntry: Record "Vendor Ledger Entry"; TotalPmtAmount: Decimal; CorrectionAmount: Decimal)
    begin
        Init();
        "Pmt. Entry No." := 0;
        CopyFromInvoiceVendLedgEntry(VendorLedgerEntry);
        InsertInvoice(TotalPmtAmount, CorrectionAmount);
    end;

    [Scope('OnPrem')]
    procedure InsertCustomerInvoice(CustLedgerEntry: Record "Cust. Ledger Entry"; TotalPmtAmount: Decimal; CorrectionAmount: Decimal)
    begin
        Init();
        "Pmt. Entry No." := 0;
        CopyFromInvoiceCustLedgEntry(CustLedgerEntry);
        InsertInvoice(TotalPmtAmount, CorrectionAmount);
    end;

    local procedure InsertInvoice(TotalPmtAmount: Decimal; CorrectionAmount: Decimal)
    begin
        "Days Since Due Date" := WorkDate() - "Due Date";
        if "Days Since Due Date" < 0 then
            "Days Since Due Date" := 0;
        "Pmt. Amount (LCY)" := TotalPmtAmount;
        "Entry Amount Corrected (LCY)" := "Entry Amount (LCY)" + CorrectionAmount;
        "Remaining Amount (LCY)" := "Entry Amount Corrected (LCY)" + "Pmt. Amount (LCY)";
        Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertVendorPayment(InvVendorLedgerEntry: Record "Vendor Ledger Entry"; PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        Init();
        CopyFromInvoiceVendLedgEntry(InvVendorLedgerEntry);
        InsertPayment(
          PmtDtldVendLedgEntry."Entry No.", PmtDtldVendLedgEntry."Posting Date",
          PmtDtldVendLedgEntry."Document No.", PmtDtldVendLedgEntry."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure InsertCustomerPayment(InvCustLedgerEntry: Record "Cust. Ledger Entry"; PmtDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        Init();
        CopyFromInvoiceCustLedgEntry(InvCustLedgerEntry);
        InsertPayment(
          PmtDtldCustLedgEntry."Entry No.", PmtDtldCustLedgEntry."Posting Date",
          PmtDtldCustLedgEntry."Document No.", PmtDtldCustLedgEntry."Amount (LCY)");
    end;

    local procedure InsertPayment(EntryNo: Integer; PmtPostingDate: Date; PmtDocNo: Code[20]; PmtAmount: Decimal)
    begin
        "Pmt. Entry No." := EntryNo;
        "Pmt. Posting Date" := PmtPostingDate;
        "Pmt. Doc. No." := PmtDocNo;
        "Pmt. Days Delayed" := "Pmt. Posting Date" - "Due Date";
        if "Pmt. Days Delayed" < 0 then
            "Pmt. Days Delayed" := 0;
        "Pmt. Amount (LCY)" := PmtAmount;
        Insert();
    end;

    [Scope('OnPrem')]
    procedure CalcSumOfAmountFields()
    begin
        CalcSums("Remaining Amount (LCY)", "Pmt. Amount (LCY)");
    end;

    local procedure CopyFromInvoiceVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Invoice Entry No." := VendorLedgerEntry."Entry No.";
        "CV No." := VendorLedgerEntry."Vendor No.";
        "Inv. External Document No." := VendorLedgerEntry."External Document No.";
        "Invoice Doc. No." := VendorLedgerEntry."Document No.";
        "Document Type" := VendorLedgerEntry."Document Type";
        "Posting Date" := VendorLedgerEntry."Posting Date";
        "Due Date" := VendorLedgerEntry."Due Date";
        "Invoice Is Open" := VendorLedgerEntry.Open;
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        "Entry Amount (LCY)" := VendorLedgerEntry."Amount (LCY)";
    end;

    local procedure CopyFromInvoiceCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        "Invoice Entry No." := CustLedgerEntry."Entry No.";
        "CV No." := CustLedgerEntry."Customer No.";
        "Invoice Doc. No." := CustLedgerEntry."Document No.";
        "Document Type" := CustLedgerEntry."Document Type";
        "Posting Date" := CustLedgerEntry."Posting Date";
        "Due Date" := CustLedgerEntry."Due Date";
        "Invoice Is Open" := CustLedgerEntry.Open;
        CustLedgerEntry.CalcFields("Amount (LCY)");
        "Entry Amount (LCY)" := CustLedgerEntry."Amount (LCY)";
    end;
}

 
#endif
