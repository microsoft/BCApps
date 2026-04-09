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
        SchemeHandler: Interface PaymentPracticeSchemeHandler;
        LastVendNo: Code[20];
    begin
        SchemeHandler := PaymentPracticeHeader."Reporting Scheme";
        LastVendNo := '';
        Vendor.SetLoadFields("No.", "Exclude from Pmt. Practices", "Company Size Code");
        VendorLedgerEntry.SetLoadFields("Entry No.", "Vendor No.", "External Document No.", "Document No.", "Posting Date", "Invoice Received Date", "Document Date", "Due Date", Open, "Closed at Date", "Closed by Entry No.", "SCF Payment Date");
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
                    if SchemeHandler.UpdatePaymentPracData(PaymentPracticeData) then
                        PaymentPracticeData.Insert();
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    procedure BuildPaymentPracticeDataForCustomer(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header")
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SchemeHandler: Interface PaymentPracticeSchemeHandler;
        LastCustNo: Code[20];
    begin
        SchemeHandler := PaymentPracticeHeader."Reporting Scheme";
        LastCustNo := '';
        Customer.SetLoadFields("No.", "Exclude from Pmt. Practices");
        CustLedgerEntry.SetLoadFields("Entry No.", "Customer No.", "External Document No.", "Document No.", "Posting Date", "Document Date", "Due Date", Open, "Closed at Date", "Closed by Entry No.");
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
                    if SchemeHandler.UpdatePaymentPracData(PaymentPracticeData) then
                        PaymentPracticeData.Insert();
                end;
            until CustLedgerEntry.Next() = 0;
    end;
}
