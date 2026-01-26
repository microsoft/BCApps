// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 10202 "Entry Application Management"
{

    trigger OnRun()
    begin
    end;

    procedure GetAppliedCustEntries(var AppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; CustLedgEntry: Record "Cust. Ledger Entry"; UseLCY: Boolean)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtCustLedgEntry: Record "Cust. Ledger Entry";
        ClosingCustLedgEntry: Record "Cust. Ledger Entry";
        AmountToApply: Decimal;
    begin
        // Temporary Table, AppliedCustLedgEntry, to be filled in with everything that CustLedgEntry applied to.
        // Note that within AppliedCustLedgEntry, the "Amount to Apply" field will be filled in with the Amount Applied.
        // IF UseLCY is TRUE, Amount Applied will be in LCY, else it will be in the application currency
        AppliedCustLedgEntry.Reset();
        AppliedCustLedgEntry.DeleteAll();

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.Find('-') then
            repeat
                PmtDtldCustLedgEntry.SetFilter("Cust. Ledger Entry No.", '<>%1', CustLedgEntry."Entry No.");
                PmtDtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
                PmtDtldCustLedgEntry.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
                PmtDtldCustLedgEntry.SetRange("Application No.", DtldCustLedgEntry."Application No.");
                PmtDtldCustLedgEntry.SetRange("Customer No.", DtldCustLedgEntry."Customer No.");
                OnGetAppliedCustEntriesOnAfterFilterPmtDtldCustLedgEntry(DtldCustLedgEntry, PmtDtldCustLedgEntry);
                PmtDtldCustLedgEntry.FindSet();
                repeat
                    if UseLCY then
                        AmountToApply := -PmtDtldCustLedgEntry."Amount (LCY)"
                    else
                        AmountToApply := -PmtDtldCustLedgEntry.Amount;
                    PmtCustLedgEntry.Get(PmtDtldCustLedgEntry."Cust. Ledger Entry No.");
                    AppliedCustLedgEntry := PmtCustLedgEntry;
                    if AppliedCustLedgEntry.Find() then begin
                        AppliedCustLedgEntry."Amount to Apply" += AmountToApply;
                        AppliedCustLedgEntry.Modify();
                    end else begin
                        AppliedCustLedgEntry := PmtCustLedgEntry;
                        AppliedCustLedgEntry."Amount to Apply" := AmountToApply;
                        if CustLedgEntry."Closed by Entry No." <> 0 then begin
                            ClosingCustLedgEntry.Get(PmtDtldCustLedgEntry."Cust. Ledger Entry No.");
                            if ClosingCustLedgEntry."Closed by Entry No." <> AppliedCustLedgEntry."Entry No." then
                                AppliedCustLedgEntry."Pmt. Disc. Given (LCY)" := 0;
                        end;
                        AppliedCustLedgEntry.Insert();
                    end;
                until PmtDtldCustLedgEntry.Next() = 0;
            until DtldCustLedgEntry.Next() = 0;
    end;

    procedure GetAppliedVendEntries(var AppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; VendLedgEntry: Record "Vendor Ledger Entry"; UseLCY: Boolean)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtVendLedgEntry: Record "Vendor Ledger Entry";
        ClosingVendLedgEntry: Record "Vendor Ledger Entry";
        AmountToApply: Decimal;
        PaymentDiscount: Decimal;
        IsHandled: Boolean;
    begin
        // Temporary Table, AppliedVendLedgEntry, to be filled in with everything that VendLedgEntry applied to.
        // Note that within AppliedVendLedgEntry, the "Amount to Apply" field will be filled in with the Amount Applied.
        // IF UseLCY is TRUE, Amount Applied will be in LCY, else it will be in the application currency
        AppliedVendLedgEntry.Reset();
        AppliedVendLedgEntry.DeleteAll();

        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.Find('-') then
            repeat
                PmtDtldVendLedgEntry.SetFilter("Vendor Ledger Entry No.", '<>%1', VendLedgEntry."Entry No.");
                PmtDtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                PmtDtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry."Transaction No.");
                PmtDtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry."Application No.");
                PmtDtldVendLedgEntry.SetRange("Vendor No.", DtldVendLedgEntry."Vendor No.");
                PmtDtldVendLedgEntry.FindSet();
                repeat
                    IsHandled := false;
                    OnGetAppliedVendEntriesOnBeforePrepareAppliedVendLedgEntry(AppliedVendLedgEntry, VendLedgEntry, UseLCY, PmtDtldVendLedgEntry, IsHandled);
                    if not IsHandled then begin
                        PaymentDiscount := 0;
                        if PmtDtldVendLedgEntry."Posting Date" <= PmtDtldVendLedgEntry."Initial Entry Due Date" then
                            PaymentDiscount := PmtDtldVendLedgEntry."Remaining Pmt. Disc. Possible";
                        if UseLCY then
                            AmountToApply := -PmtDtldVendLedgEntry."Amount (LCY)" - PaymentDiscount
                        else
                            AmountToApply := -PmtDtldVendLedgEntry.Amount - PaymentDiscount;
                        PmtVendLedgEntry.Get(PmtDtldVendLedgEntry."Vendor Ledger Entry No.");
                        AppliedVendLedgEntry := PmtVendLedgEntry;
                        if AppliedVendLedgEntry.Find() then begin
                            AppliedVendLedgEntry."Amount to Apply" += AmountToApply;
                            AppliedVendLedgEntry.Modify();
                        end else begin
                            AppliedVendLedgEntry := PmtVendLedgEntry;
                            AppliedVendLedgEntry."Amount to Apply" := AmountToApply;
                            if VendLedgEntry."Closed by Entry No." <> 0 then begin
                                ClosingVendLedgEntry.Get(PmtDtldVendLedgEntry."Vendor Ledger Entry No.");
                                if ClosingVendLedgEntry."Closed by Entry No." <> AppliedVendLedgEntry."Entry No." then
                                    AppliedVendLedgEntry."Pmt. Disc. Rcd.(LCY)" := 0;
                            end;
                            AppliedVendLedgEntry.Insert();
                        end;
                    end;
                until PmtDtldVendLedgEntry.Next() = 0;
            until DtldVendLedgEntry.Next() = 0;
    end;

    procedure GetAppliedVendorEntries(var
                                          TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
                                          VendorNo: Code[20];
                                          PeriodDate: array[2] of Date;
                                          UseLCY: Boolean)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PmtVendLedgEntry: Record "Vendor Ledger Entry";
        ClosingVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempInteger: Record "Integer" temporary;
        AmountToApply: Decimal;
        PaymentDiscountEntries: List of [Integer];
    begin
        TempAppliedVendLedgEntry.Reset();
        TempAppliedVendLedgEntry.DeleteAll();

        VendLedgEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        VendLedgEntry.SetLoadFields("Document Type", "Vendor No.", "Posting Date", "Closed by Entry No.");
        VendLedgEntry.SetFilter("Document Type", '%1|%2', VendLedgEntry."Document Type"::Payment, VendLedgEntry."Document Type"::Refund);
        if VendorNo <> '' then
            VendLedgEntry.SetRange("Vendor No.", VendorNo);
        VendLedgEntry.SetRange("Posting Date", PeriodDate[1], PeriodDate[2]);
        if VendLedgEntry.FindSet() then
            repeat
                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
                DtldVendLedgEntry.SetLoadFields("Vendor Ledger Entry No.", "Entry Type", Unapplied, "Transaction No.", "Application No.");
                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                DtldVendLedgEntry.SetRange(Unapplied, false);
                if DtldVendLedgEntry.FindSet() then
                    repeat
                        PmtDtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
                        PmtDtldVendLedgEntry.SetLoadFields("Vendor Ledger Entry No.", "Entry Type", "Vendor No.", "Transaction No.", "Application No.", Amount, "Amount (LCY)");
                        PmtDtldVendLedgEntry.SetFilter("Vendor Ledger Entry No.", '<>%1', VendLedgEntry."Entry No.");
                        PmtDtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                        if VendorNo <> '' then
                            PmtDtldVendLedgEntry.SetRange("Vendor No.", VendorNo);
                        PmtDtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry."Transaction No.");
                        PmtDtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry."Application No.");
                        PmtDtldVendLedgEntry.FindSet();
                        repeat
                            if TryCacheEntryNo(TempInteger, PmtDtldVendLedgEntry."Entry No.") then begin
                                if UseLCY then
                                    AmountToApply := -PmtDtldVendLedgEntry."Amount (LCY)"
                                else
                                    AmountToApply := -PmtDtldVendLedgEntry.Amount;
                                PmtVendLedgEntry.Get(PmtDtldVendLedgEntry."Vendor Ledger Entry No.");
                                TempAppliedVendLedgEntry := PmtVendLedgEntry;
                                if TempAppliedVendLedgEntry.Find() then begin
                                    TempAppliedVendLedgEntry."Amount to Apply" += AmountToApply;
                                    TempAppliedVendLedgEntry.Modify();
                                end else begin
                                    TempAppliedVendLedgEntry := PmtVendLedgEntry;
                                    TempAppliedVendLedgEntry."Amount to Apply" := AmountToApply;

                                    if VendLedgEntry."Closed by Entry No." <> 0 then begin
                                        ClosingVendLedgEntry.Get(PmtDtldVendLedgEntry."Vendor Ledger Entry No.");
                                        if ClosingVendLedgEntry."Closed by Entry No." <> TempAppliedVendLedgEntry."Entry No." then
                                            TempAppliedVendLedgEntry."Pmt. Disc. Rcd.(LCY)" := 0;
                                        if not PaymentDiscountEntries.Contains(ClosingVendLedgEntry."Closed by Entry No.") then begin
                                            TempAppliedVendLedgEntry."Amount to Apply" +=
                                                GetPaymentDiscount(ClosingVendLedgEntry."Closed by Entry No.", UseLCY);
                                            PaymentDiscountEntries.Add(ClosingVendLedgEntry."Closed by Entry No.");
                                        end;
                                    end;
                                    TempAppliedVendLedgEntry.Insert();
                                end;
                            end;
                        until PmtDtldVendLedgEntry.Next() = 0;
                    until DtldVendLedgEntry.Next() = 0;
            until VendLedgEntry.Next() = 0;
    end;

    local procedure GetPaymentDiscount(ClosingVendLedgEntryNo: Integer; UseLCY: Boolean): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendLedgEntry.SetLoadFields("Vendor Ledger Entry No.", "Entry Type", Unapplied, Amount, "Amount (LCY)");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", ClosingVendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Payment Discount");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindFirst() then
            if UseLCY then
                exit(DtldVendLedgEntry."Amount (LCY)")
            else
                exit(DtldVendLedgEntry.Amount);
        exit(0);
    end;

    local procedure TryCacheEntryNo(var TempInteger: Record "Integer" temporary; EntryNo: Integer): Boolean
    begin
        TempInteger.Number := EntryNo;
        exit(TempInteger.Insert());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAppliedCustEntriesOnAfterFilterPmtDtldCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var PmtDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAppliedVendEntriesOnBeforePrepareAppliedVendLedgEntry(var AppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var VendLedgEntry: Record "Vendor Ledger Entry"; var UseLCY: Boolean; var PmtDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;
}

