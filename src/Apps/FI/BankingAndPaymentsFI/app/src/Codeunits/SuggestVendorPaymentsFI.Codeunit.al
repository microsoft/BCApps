// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;

codeunit 13592 "Suggest Vendor Payments FI"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        JournalContext: Record "Gen. Journal Line";
        SentToBank: Boolean;
#if not CLEAN30
        Feature: Codeunit "Banking Payments Feature FI";
#endif

    internal procedure Initialize(NewSentToBank: Boolean; NewJournalContext: Record "Gen. Journal Line")
    begin
        SentToBank := NewSentToBank;
        JournalContext := NewJournalContext;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnGetVendLedgEntriesOnBeforeSaveAmount', '', false, false)]
    local procedure SelectEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; LastDueDateToPay: Date; var PostingDate: Date; var IsHandled: Boolean)
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if IsHandled or not SentToBank then
            exit;
        SetExportFilters(Exported, VendorLedgerEntry."Entry No.", GenJournalLine);
        Exported.SetRange("Payment Date", 0D, LastDueDateToPay);
        if Exported.Find('-') then
            PostingDate := Exported."Payment Date"
        else
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnSaveAmountOnBeforeSetPayableAmounts', '', false, false)]
    local procedure OverrideAmount(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; JournalContext: Record "Gen. Journal Line")
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if not SentToBank then
            exit;
        SetExportFilters(Exported, VendorLedgerEntry."Entry No.", JournalContext);
        // Preserve the last assignment, including the already calculated LCY amount.
        if Exported.Find('-') then
            GenJournalLine.Amount := 0;
        repeat
            GenJournalLine.Amount := Exported.Amount;
        until Exported.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsertNonSummarize', '', false, false)]
    local procedure FillNonSummarizedBuffer(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    var
        Exported: Record "Ref. Payment - Exported FI";
        Posting: Codeunit "Banking Payments Posting FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Posting.CopyVendorPaymentFields(TempVendorPaymentBuffer, VendorLederEntry, TempPayableVendorLedgerEntry);
        SetExportFilters(Exported, VendorLederEntry."Entry No.", JournalContext);
        if Exported.Find('+') then begin
            TempVendorPaymentBuffer."Payment Bal. Account No." := Exported."Payment Account";
            TempVendorPaymentBuffer."Planned Payment Date" := Exported."Payment Date";
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnInsertGenJournalLineOnBeforeSetPostingDate', '', false, false)]
    local procedure SetDomesticPaymentDate(var GenJournalLine: Record "Gen. Journal Line"; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; var IsHandled: Boolean)
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if IsHandled then
            exit;
        Exported.SetRange(Transferred, true);
        Exported.SetRange("Posted to G/L", false);
        Exported.SetRange("Entry No.", TempVendorPaymentBuffer."Vendor Ledg. Entry No.");
        GenJournalLine."Posting Date" := 0D;
        if Exported.FindLast() then
            GenJournalLine."Posting Date" := Exported."Payment Date";
        IsHandled := true;
    end;

    local procedure SetExportFilters(var Exported: Record "Ref. Payment - Exported FI"; EntryNo: Integer; GenJournalLine: Record "Gen. Journal Line")
    begin
        Exported.Reset();
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account" then
            Exported.SetFilter("Payment Account", GenJournalLine."Bal. Account No.");
        Exported.SetRange(Transferred, true);
        Exported.SetRange("Posted to G/L", false);
        Exported.SetRange("Entry No.", EntryNo);
    end;
}
