// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 10840 "No Taxable - Generate Entries"
{
    Permissions = TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
        UpdateNoTaxableVATEntries();

        if CheckNoTaxableEntriesExist() then
            exit;

        InsertNoTaxableEntryCustomer();
        InsertNoTaxableEntryVendor();
    end;

    var
        NoTaxableMgt: Codeunit "No Taxable Mgt.";

    local procedure CheckNoTaxableEntriesExist(): Boolean
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        exit(not NoTaxableEntry.IsEmpty);
    end;

    local procedure InsertNoTaxableEntryVendor()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetFilter("Document Type", '%1|%2', VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange(Reversed, false);
        if VendorLedgerEntry.FindSet() then
            repeat
                NoTaxableMgt.UpdateNoTaxableEntryFromVendorLedgerEntry(VendorLedgerEntry);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure InsertNoTaxableEntryCustomer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange(Reversed, false);
        if CustLedgerEntry.FindSet() then
            repeat
                NoTaxableMgt.UpdateNoTaxableEntryFromCustomerLedgerEntry(CustLedgerEntry);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure UpdateNoTaxableVATEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        VATPostingSetup.SetFilter("No Taxable Type", '>%1', VATPostingSetup."No Taxable Type"::" ");
        if VATPostingSetup.FindSet() then
            repeat
                VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                if not VATEntry.IsEmpty() then
                    VATEntry.ModifyAll("No Taxable Type", VATPostingSetup."No Taxable Type");
            until VATPostingSetup.Next() = 0;
    end;
}

