// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;

codeunit 9083 "Calculate Vendor Stats."
{
    trigger OnRun()
    var
        Vendor: record Vendor;
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        VendorNo: Code[20];
        BalanceAsCustomer: Decimal;
        LinkedCustomerNo: Code[20];
    begin
        Params := Page.GetBackgroundParameters();
        VendorNo := CopyStr(Params.Get(GetVendorNoLabel()), 1, MaxStrLen(VendorNo));
        if not Vendor.Get(VendorNo) then
            exit;

        BalanceAsCustomer := Vendor.GetBalanceAsCustomer(LinkedCustomerNo);

        Results.Add(GetLinkedCustomerNoLabel(), Format(LinkedCustomerNo));
        Results.Add(GetBalanceAsCustomerLabel(), Format(BalanceAsCustomer));
        Results.Add(GetLastPaymentDateLabel(), Format(GetLastPaymentDate(VendorNo)));
        Results.Add(GetOverdueBalanceLabel(), Format(Vendor.CalcOverdueBalance()));
        Results.Add(GetInvoicedPrepmtAmountLCYLabel(), Format(Vendor.GetInvoicedPrepmtAmountLCY()));

        OnCalculateVendorStatistics(Params, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        LastPaymentDateLbl: label 'Last Payment Date', Locked = true;
        OverdueBalanceLbl: label 'Overdue Balance', Locked = true;
        InvoicedPrepmtAmountLCYLbl: label 'Invoiced Prepmt Amount LCY', Locked = true;
        VendorNoLbl: label 'Vendor No.', Locked = true;
        BalanceAsCustomerLbl: Label 'BalanceAsCustomer', Locked = true;
        LinkedCustomerNoLbl: Label 'LinkedCustomerNo', Locked = true;

    local procedure GetLastPaymentDate(VendorNo: Code[20]): Date
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SetFilterLastPaymentDateEntry(VendorNo, VendorLedgerEntry);
        if VendorLedgerEntry.FindLast() then;
        exit(VendorLedgerEntry."Posting Date");
    end;

    local procedure SetFilterLastPaymentDateEntry(VendorNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;


    internal procedure GetLastPaymentDateLabel(): Text
    begin
        exit(LastPaymentDateLbl);
    end;

    internal procedure GetOverdueBalanceLabel(): Text
    begin
        exit(OverdueBalanceLbl);
    end;

    internal procedure GetInvoicedPrepmtAmountLCYLabel(): Text
    begin
        exit(InvoicedPrepmtAmountLCYLbl);
    end;

    internal procedure GetVendorNoLabel(): Text
    begin
        exit(VendorNoLbl);
    end;

    internal procedure GetBalanceAsCustomerLabel(): Text
    begin
        exit(BalanceAsCustomerLbl);
    end;

    internal procedure GetLinkedCustomerNoLabel(): Text
    begin
        exit(LinkedCustomerNoLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVendorStatistics(Params: Dictionary of [Text, Text]; var Results: Dictionary of [Text, Text])
    begin
    end;
}
