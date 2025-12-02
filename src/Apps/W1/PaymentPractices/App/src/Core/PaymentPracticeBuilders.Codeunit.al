// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 688 "Payment Practice Builders"
{
    Access = internal;

    procedure BuildPaymentPracticeDataForVendor(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header")
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LastVendNo: Code[20];
    begin
        LastVendNo := '';
        VendorLedgerEntry.SetCurrentKey("Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Posting Date", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
        if VendorLedgerEntry.FindSet() then
            repeat
                if LastVendNo <> VendorLedgerEntry."Vendor No." then begin
                    Vendor.Get(VendorLedgerEntry."Vendor No.");
                    LastVendNo := Vendor."No.";
                end;
                if Vendor."Exclude from Pmt. Practices" then begin
                    // Skip all entries associated with this Vendor
                    VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
                    VendorLedgerEntry.FindLast();
                    VendorLedgerEntry.SetRange("Vendor No.");
                end else begin
                    PaymentPracticeData.Init();
                    PaymentPracticeData."Header No." := PaymentPracticeHeader."No.";
                    PaymentPracticeData.CopyFromInvoiceVendLedgEntry(VendorLedgerEntry);
                    PaymentPracticeData."Company Size Code" := Vendor."Company Size Code";
                    PaymentPracticeData.Insert();
                    if PaymentPracticeHeader."Generate Payment Data" then
                        BuildPaymentsForVendorInvoice(VendorLedgerEntry, PaymentPracticeHeader."No.");
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    procedure BuildPaymentPracticeDataForCustomer(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header")
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LastCustNo: Code[20];
    begin
        LastCustNo := '';
        CustLedgerEntry.SetCurrentKey("Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Posting Date", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
        if CustLedgerEntry.FindSet() then
            repeat
                if LastCustNo <> CustLedgerEntry."Customer No." then begin
                    Customer.Get(CustLedgerEntry."Customer No.");
                    LastCustNo := Customer."No.";
                end;
                if Customer."Exclude from Pmt. Practices" then begin
                    // Skip all entries associated with this Customer
                    CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                    CustLedgerEntry.FindLast();
                    CustLedgerEntry.SetRange("Customer No.");
                end else begin
                    PaymentPracticeData.Init();
                    PaymentPracticeData."Header No." := PaymentPracticeHeader."No.";
                    PaymentPracticeData.CopyFromInvoiceCustLedgEntry(CustLedgerEntry);
                    PaymentPracticeData.Insert();
                    if PaymentPracticeHeader."Generate Payment Data" then
                        BuildPaymentsForCustomerInvoice(CustLedgerEntry, PaymentPracticeHeader."No.");
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure BuildPaymentsForVendorInvoice(InvoiceVendorLedgerEntry: Record "Vendor Ledger Entry"; HeaderNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PaymentVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Case 1: Payment applied to Invoice - detailed entry is on the invoice side
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", InvoiceVendorLedgerEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1', InvoiceVendorLedgerEntry."Entry No.");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if PaymentVendorLedgerEntry.Get(DtldVendLedgEntry."Applied Vend. Ledger Entry No.") then
                    if PaymentVendorLedgerEntry."Document Type" = PaymentVendorLedgerEntry."Document Type"::Payment then
                        InsertVendorPaymentApplication(InvoiceVendorLedgerEntry, PaymentVendorLedgerEntry, DtldVendLedgEntry."Amount (LCY)", HeaderNo);
            until DtldVendLedgEntry.Next() = 0;

        // Case 2: Invoice applied to Payment - detailed entry is on the payment side
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.", InvoiceVendorLedgerEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if DtldVendLedgEntry."Applied Vend. Ledger Entry No." <> DtldVendLedgEntry."Vendor Ledger Entry No." then       // do not process self-applications
                    if PaymentVendorLedgerEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.") then
                        if PaymentVendorLedgerEntry."Document Type" = PaymentVendorLedgerEntry."Document Type"::Payment then
                            InsertVendorPaymentApplication(InvoiceVendorLedgerEntry, PaymentVendorLedgerEntry, DtldVendLedgEntry."Amount (LCY)", HeaderNo);
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure InsertVendorPaymentApplication(InvoiceVendorLedgerEntry: Record "Vendor Ledger Entry"; PaymentVendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedAmountLCY: Decimal; HeaderNo: Integer)
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
    begin
        PaymentPracticePmtData.Init();
        PaymentPracticePmtData.CopyFromVendorApplication(InvoiceVendorLedgerEntry, PaymentVendorLedgerEntry, AppliedAmountLCY, HeaderNo);
        if PaymentPracticePmtData.Insert() then;
    end;

    local procedure BuildPaymentsForCustomerInvoice(InvoiceCustLedgerEntry: Record "Cust. Ledger Entry"; HeaderNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Case 1: Payment applied to Invoice - detailed entry is on the invoice side
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", InvoiceCustLedgerEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', InvoiceCustLedgerEntry."Entry No.");
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if PaymentCustLedgerEntry.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
                    if PaymentCustLedgerEntry."Document Type" = PaymentCustLedgerEntry."Document Type"::Payment then
                        InsertCustomerPaymentApplication(InvoiceCustLedgerEntry, PaymentCustLedgerEntry, DtldCustLedgEntry."Amount (LCY)", HeaderNo);
            until DtldCustLedgEntry.Next() = 0;

        // Case 2: Invoice applied to Payment - detailed entry is on the payment side
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", InvoiceCustLedgerEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Applied Cust. Ledger Entry No." <> DtldCustLedgEntry."Cust. Ledger Entry No." then       // do not process self-applications
                    if PaymentCustLedgerEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.") then
                        if PaymentCustLedgerEntry."Document Type" = PaymentCustLedgerEntry."Document Type"::Payment then
                            InsertCustomerPaymentApplication(InvoiceCustLedgerEntry, PaymentCustLedgerEntry, DtldCustLedgEntry."Amount (LCY)", HeaderNo);
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure InsertCustomerPaymentApplication(InvoiceCustLedgerEntry: Record "Cust. Ledger Entry"; PaymentCustLedgerEntry: Record "Cust. Ledger Entry"; AppliedAmountLCY: Decimal; HeaderNo: Integer)
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
    begin
        PaymentPracticePmtData.Init();
        PaymentPracticePmtData.CopyFromCustomerApplication(InvoiceCustLedgerEntry, PaymentCustLedgerEntry, AppliedAmountLCY, HeaderNo);
        if PaymentPracticePmtData.Insert() then;
    end;
}
