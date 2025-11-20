// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

table 1248 "Ledger Entry Matching Buffer"
{
    Caption = 'Ledger Entry Matching Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Account Type"; Enum "Matching Ledger Account Type")
        {
            Caption = 'Account Type';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(4; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(5; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
        }
        field(7; Description; Text[100])
        {
        }
        field(8; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(13; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(20; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(21; "Remaining Amt. Incl. Discount"; Decimal)
        {
            Caption = 'Remaining Amt. Incl. Discount';
        }
        field(22; "Pmt. Discount Due Date"; Date)
        {
            Caption = 'Pmt. Discount Due Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Account Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertFromCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; UseLCYAmounts: Boolean; var UsePaymentDiscounts: Boolean)
    begin
        OnBeforeProcedureInsertFromCustomerLedgerEntry(CustLedgerEntry);
        Clear(Rec);
        "Entry No." := CustLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgerEntry."Customer No.";
        "Due Date" := CustLedgerEntry."Due Date";
        "Posting Date" := CustLedgerEntry."Posting Date";
        "Document No." := CustLedgerEntry."Document No.";
        "External Document No." := CustLedgerEntry."External Document No.";
        "Payment Reference" := CustLedgerEntry."Payment Reference";

        if UseLCYAmounts then
            "Remaining Amount" := CustLedgerEntry."Remaining Amt. (LCY)"
        else
            "Remaining Amount" := CustLedgerEntry."Remaining Amount";

        "Pmt. Discount Due Date" := GetCustomerLedgerEntryDiscountDueDate(CustLedgerEntry);

        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        if "Pmt. Discount Due Date" > 0D then begin
            if UseLCYAmounts then
                "Remaining Amt. Incl. Discount" -=
                  Round(CustLedgerEntry."Remaining Pmt. Disc. Possible" / CustLedgerEntry."Adjusted Currency Factor")
            else
                "Remaining Amt. Incl. Discount" -= CustLedgerEntry."Remaining Pmt. Disc. Possible";
            UsePaymentDiscounts := true;
        end;
        OnBeforeInsertFromCustomerLedgerEntry(Rec, CustLedgerEntry);
        Insert(true);
    end;

    procedure InsertFromVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; UseLCYAmounts: Boolean; var UsePaymentDiscounts: Boolean)
    begin
        OnBeforeProcedureInsertFromVendorLedgerEntry(VendorLedgerEntry);
        Clear(Rec);
        "Entry No." := VendorLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendorLedgerEntry."Vendor No.";
        "Due Date" := VendorLedgerEntry."Due Date";
        "Posting Date" := VendorLedgerEntry."Posting Date";
        "Document No." := VendorLedgerEntry."Document No.";
        "External Document No." := VendorLedgerEntry."External Document No.";
        "Payment Reference" := VendorLedgerEntry."Payment Reference";

        if UseLCYAmounts then
            "Remaining Amount" := VendorLedgerEntry."Remaining Amt. (LCY)"
        else
            "Remaining Amount" := VendorLedgerEntry."Remaining Amount";

        "Pmt. Discount Due Date" := GetVendorLedgerEntryDiscountDueDate(VendorLedgerEntry);

        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        if "Pmt. Discount Due Date" > 0D then begin
            if UseLCYAmounts then
                "Remaining Amt. Incl. Discount" -=
                  Round(VendorLedgerEntry."Remaining Pmt. Disc. Possible" / VendorLedgerEntry."Adjusted Currency Factor")
            else
                "Remaining Amt. Incl. Discount" -= VendorLedgerEntry."Remaining Pmt. Disc. Possible";
            UsePaymentDiscounts := true;
        end;
        OnBeforeInsertFromVendorLedgerEntry(Rec, VendorLedgerEntry);
        Insert(true);
    end;

    procedure InsertFromEmployeeLedgerEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        InsertFromEmployeeLedgerEntry(EmployeeLedgerEntry, false);
    end;

    procedure InsertFromEmployeeLedgerEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; UseLCYAmounts: Boolean)
    begin
        Clear(Rec);
        "Entry No." := EmployeeLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::Employee;
        "Account No." := EmployeeLedgerEntry."Employee No.";
        "Posting Date" := EmployeeLedgerEntry."Posting Date";
        "Document No." := EmployeeLedgerEntry."Document No.";
        "Payment Reference" := EmployeeLedgerEntry."Payment Reference";

        if UseLCYAmounts then
            "Remaining Amount" := EmployeeLedgerEntry."Remaining Amt. (LCY)"
        else
            "Remaining Amount" := EmployeeLedgerEntry."Remaining Amount";

        OnBeforeInsertFromEmployeeLedgerEntry(Rec, EmployeeLedgerEntry);
        Insert(true);
    end;

    procedure InsertFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        Clear(Rec);
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Account Type" := "Account Type"::"Bank Account";
        "Account No." := BankAccountLedgerEntry."Bank Account No.";
        "Bal. Account Type" := BankAccountLedgerEntry."Bal. Account Type";
        "Bal. Account No." := BankAccountLedgerEntry."Bal. Account No.";
        Description := BankAccountLedgerEntry.Description;
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "External Document No." := BankAccountLedgerEntry."External Document No.";
        "Remaining Amount" := BankAccountLedgerEntry."Remaining Amount";
        "Remaining Amt. Incl. Discount" := "Remaining Amount";
        OnBeforeInsertFromBankAccountLedgerEntry(Rec, BankAccountLedgerEntry);
        Insert(true);
    end;

    procedure GetApplicableRemainingAmount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; UsePaymentDiscounts: Boolean): Decimal
    begin
        if not UsePaymentDiscounts then
            exit("Remaining Amount");

        if BankAccReconciliationLine."Transaction Date" > "Pmt. Discount Due Date" then
            exit("Remaining Amount");

        exit("Remaining Amt. Incl. Discount");
    end;

    procedure GetNoOfLedgerEntriesWithinRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; UsePaymentDiscounts: Boolean): Integer
    begin
        exit(GetNoOfLedgerEntriesInAmountRange(MinAmount, MaxAmount, TransactionDate, '>=%1&<=%2', UsePaymentDiscounts));
    end;

    procedure GetNoOfLedgerEntriesOutsideRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; UsePaymentDiscounts: Boolean): Integer
    begin
        exit(GetNoOfLedgerEntriesInAmountRange(MinAmount, MaxAmount, TransactionDate, '<%1|>%2', UsePaymentDiscounts));
    end;

    local procedure GetNoOfLedgerEntriesInAmountRange(MinAmount: Decimal; MaxAmount: Decimal; TransactionDate: Date; RangeFilter: Text; UsePaymentDiscounts: Boolean): Integer
    var
        NoOfEntreis: Integer;
    begin
        SetFilter("Remaining Amount", RangeFilter, MinAmount, MaxAmount);
        SetFilter("Pmt. Discount Due Date", '<%1', TransactionDate);
        NoOfEntreis := Count;

        SetRange("Remaining Amount");

        if UsePaymentDiscounts then begin
            SetFilter("Remaining Amt. Incl. Discount", RangeFilter, MinAmount, MaxAmount);
            SetFilter("Pmt. Discount Due Date", '>=%1', TransactionDate);
            NoOfEntreis += Count;
            SetRange("Remaining Amt. Incl. Discount");
        end;

        SetRange("Pmt. Discount Due Date");

        exit(NoOfEntreis);
    end;

    local procedure GetCustomerLedgerEntryDiscountDueDate(CustLedgerEntry: Record "Cust. Ledger Entry"): Date
    begin
        if CustLedgerEntry."Remaining Pmt. Disc. Possible" = 0 then
            exit(0D);

        if CustLedgerEntry."Pmt. Disc. Tolerance Date" >= CustLedgerEntry."Pmt. Discount Date" then
            exit(CustLedgerEntry."Pmt. Disc. Tolerance Date");

        exit(CustLedgerEntry."Pmt. Discount Date");
    end;

    local procedure GetVendorLedgerEntryDiscountDueDate(VendorLedgerEntry: Record "Vendor Ledger Entry"): Date
    begin
        if VendorLedgerEntry."Remaining Pmt. Disc. Possible" = 0 then
            exit(0D);

        if VendorLedgerEntry."Pmt. Disc. Tolerance Date" >= VendorLedgerEntry."Pmt. Discount Date" then
            exit(VendorLedgerEntry."Pmt. Disc. Tolerance Date");

        exit(VendorLedgerEntry."Pmt. Discount Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromCustomerLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromEmployeeLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromVendorLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromBankAccountLedgerEntry(var LedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcedureInsertFromVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcedureInsertFromCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

