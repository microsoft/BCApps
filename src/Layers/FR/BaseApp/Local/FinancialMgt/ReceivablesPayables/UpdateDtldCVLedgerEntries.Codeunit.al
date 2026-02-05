// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 10881 "Update Dtld. CV Ledger Entries"
{

    trigger OnRun()
    begin
        UpdateUnrealizedAdjmtGLAccDtldCustLedgerEntries();
        UpdateUnrealizedAdjmtGLAccDtldVendLedgerEntries();
    end;

    local procedure UpdateUnrealizedAdjmtGLAccDtldCustLedgerEntries()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if Customer.FindSet() then
            repeat
                DetailedCustLedgEntry.SetRange("Customer No.", Customer."No.");
                DetailedCustLedgEntry.SetFilter(
                  "Entry Type", '%1|%2',
                  DetailedCustLedgEntry."Entry Type"::"Unrealized Gain", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
                if not DetailedCustLedgEntry.IsEmpty() then
                    DetailedCustLedgEntry.ModifyAll(
                      "Curr. Adjmt. G/L Account No.", GetCustomerReceivablesAccount(Customer."No."));
            until Customer.Next() = 0;
    end;

    local procedure UpdateUnrealizedAdjmtGLAccDtldVendLedgerEntries()
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if Vendor.FindSet() then
            repeat
                DetailedVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
                DetailedVendorLedgEntry.SetFilter(
                  "Entry Type", '%1|%2',
                  DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
                if not DetailedVendorLedgEntry.IsEmpty() then
                    DetailedVendorLedgEntry.ModifyAll(
                      "Curr. Adjmt. G/L Account No.", GetVendorPayablesAccount(Vendor."No."));
            until Vendor.Next() = 0;
    end;

    local procedure GetCustomerReceivablesAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.SetLoadFields("Customer Posting Group");
        if not Customer.Get(CustomerNo) then
            exit('');

        CustomerPostingGroup.SetLoadFields("Receivables Account");
        if not CustomerPostingGroup.Get(Customer."Customer Posting Group") then
            exit('');

        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetVendorPayablesAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.SetLoadFields("Vendor Posting Group");
        if not Vendor.Get(VendorNo) then
            exit('');

        VendorPostingGroup.SetLoadFields("Payables Account");
        if not VendorPostingGroup.Get(Vendor."Vendor Posting Group") then
            exit('');

        exit(VendorPostingGroup."Payables Account");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterInitDtldCustLedgerEntry', '', false, false)]
    local procedure UpdateDtldCustLedgerEntryCurrAdjmtAccNo(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        DetailedCustLedgEntry."Curr. Adjmt. G/L Account No." := GetCustomerReceivablesAccount(DetailedCustLedgEntry."Customer No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterInitDtldVendLedgerEntry', '', false, false)]
    local procedure UpdateDtldVendLedgerEntryCurrAdjmtAccNo(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        DetailedVendorLedgEntry."Curr. Adjmt. G/L Account No." := GetVendorPayablesAccount(DetailedVendorLedgEntry."Vendor No.");
    end;
}
