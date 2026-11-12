// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

codeunit 13579 "Banking Payments Posting FI"
{
    Access = Internal;
    Permissions = tabledata "Ref. Payment - Imported FI" = m,
                  tabledata "Ref. Payment - Exported FI" = m;

#if not CLEAN30
    var
        Feature: Codeunit "Banking Payments Feature FI";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostCustOnAfterInitCustLedgEntry', '', false, false)]
    local procedure PostCustomer(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        PaymentTerms: Record "Payment Terms";
        Imported: Record "Ref. Payment - Imported FI";
        Payments: Codeunit "Ref. Payment Management FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if GenJournalLine."Payment Reference No." <> '' then
            CustLedgEntry."Payment Reference No." := GenJournalLine."Payment Reference No."
        else
            CustLedgEntry."Payment Reference No." := CopyStr(GenJournalLine."Payment Message", 1, MaxStrLen(CustLedgEntry."Payment Reference No."));
        Imported.SetRange("Reference No.", GenJournalLine."Payment Reference No.");
        Imported.SetRange("Customer No.", GenJournalLine."Account No.");
        Imported.SetRange("Posted to G/L", false);
        if Imported.FindFirst() then begin
            Imported."Posted to G/L" := true;
            Imported.Modify();
        end;

        CustLedgEntry."Disreg. Full Payment Discount" := false;
        if PaymentTerms.Get(GenJournalLine."Payment Terms Code") then
            CustLedgEntry."Disreg. Full Payment Discount" := PaymentTerms."Disreg. Full Payment Discount";
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment then
            Payments.CheckIfPaidInFull(GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cancel Posted Purch. Cr. Memo", 'OnAfterCreateCopyDocument', '', false, false)]
    local procedure InitializeCorrectivePurchaseMessage(var PurchaseHeader: Record "Purchase Header")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        PurchaseHeader.Validate("Bank Message Type", PurchaseHeader."Bank Message Type"::Message);
        PurchaseHeader.Validate("Payment Message", PurchaseHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Line", 'OnAfterCopyFromCustLedgEntry', '', false, false)]
    local procedure CopyReminderReference(var ReminderLine: Record "Reminder Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        ReminderLine."Payment Reference No." := CustLedgerEntry."Payment Reference No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostVendOnAfterInitVendLedgEntry', '', false, false)]
    local procedure PostVendor(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        VendLedgEntry."Bank Message Type" := GenJnlLine."Bank Message Type";
        VendLedgEntry."Payment Message" := GenJnlLine."Payment Message";
        VendLedgEntry."Payment Message 2" := GenJnlLine."Payment Message 2";
        VendLedgEntry."Planned Payment Date" := GenJnlLine."Planned Payment Date";
        if VendLedgEntry."Planned Payment Date" = 0D then
            VendLedgEntry."Planned Payment Date" := GenJnlLine."Due Date";
        Exported.SetCurrentKey("Document No.");
        Exported.SetRange("Document No.", GenJnlLine."Document No.");
        Exported.SetRange("Vendor No.", GenJnlLine."Account No.");
        Exported.SetRange("Invoice Message", GenJnlLine."Payment Message");
        Exported.SetRange("Posted to G/L", false);
        Exported.SetRange(Transferred, true);
        if Exported.FindFirst() then begin
            Exported."Posted to G/L" := true;
            Exported.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnCustPostApplyCustLedgEntryOnBeforeApplyCustLedgEntry', '', false, false)]
    local procedure ApplyCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        Payments: Codeunit "Ref. Payment Management FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Customer.Get(CustLedgerEntry."Customer No.");
        if Customer."Payment Terms Code" <> '' then begin
            CustLedgerEntry."Disreg. Full Payment Discount" := false;
            if PaymentTerms.Get(Customer."Payment Terms Code") then
                CustLedgerEntry."Disreg. Full Payment Discount" := PaymentTerms."Disreg. Full Payment Discount";
        end;
        if GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment then
            Payments.CheckIfPaidInFull(GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', false, false)]
    local procedure CopyPurchase(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        CopyPurchaseFields(PurchaseHeader, GenJournalLine);
        GenJournalLine."Planned Payment Date" := PurchaseHeader."Due Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost', '', false, false)]
    local procedure CopyPurchasePrepayment(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        CopyPurchaseFields(PurchaseHeader, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure CopyPostedPurchase(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        PurchInvHeader."Bank Message Type" := PurchHeader."Bank Message Type";
        PurchInvHeader."Payment Message" := PurchHeader."Payment Message";
        PurchInvHeader."Payment Message 2" := PurchHeader."Payment Message 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnCheckPurchDocumentOnBeforeCheckPurchDim', '', false, false)]
    local procedure CheckPurchase(var PurchaseHeader: Record "Purchase Header")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if PurchaseHeader.Invoice and (PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::Order]) then
            PurchaseHeader.TestField("Payment Message");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnLookUpAppliesToDocCustOnAfterApplyCustEntriesGetRecord', '', false, false)]
    local procedure LookupCustomer(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        GenJournalLine."Payment Reference No." := CustLedgerEntry."Payment Reference No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnLookUpAppliesToDocVendOnAfterApplyVendEntriesGetRecord', '', false, false)]
    local procedure LookupVendor(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        GenJournalLine."Bank Message Type" := VendLedgEntry."Bank Message Type";
        GenJournalLine."Payment Message" := VendLedgEntry."Payment Message";
        GenJournalLine."Payment Message 2" := VendLedgEntry."Payment Message 2";
    end;

    local procedure CopyPurchaseFields(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Bank Message Type" := PurchaseHeader."Bank Message Type";
        GenJournalLine."Payment Message" := PurchaseHeader."Payment Message";
        GenJournalLine."Payment Message 2" := PurchaseHeader."Payment Message 2";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsert', '', false, false)]
    local procedure FillVendorBuffer(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        CopyVendorPaymentFields(TempVendorPaymentBuffer, VendorLederEntry, TempPayableVendorLedgerEntry);
    end;

    internal procedure CopyVendorPaymentFields(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry"; TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
        TempVendorPaymentBuffer."Bank Message Type" := VendorLedgerEntry."Bank Message Type";
        TempVendorPaymentBuffer."Payment Message" := VendorLedgerEntry."Payment Message";
        TempVendorPaymentBuffer."Payment Message 2" := VendorLedgerEntry."Payment Message 2";
        TempVendorPaymentBuffer."Planned Payment Date" := VendorLedgerEntry."Planned Payment Date";
        TempVendorPaymentBuffer."Attached Payment Line No." := TempPayableVendorLedgerEntry."Attached Payment Line No.";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Vendor Payments", 'OnBeforeUpdateGnlJnlLineDimensionsFromVendorPaymentBuffer', '', false, false)]
    local procedure CopyVendorBuffer(var GenJournalLine: Record "Gen. Journal Line"; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        GenJournalLine."Bank Message Type" := TempVendorPaymentBuffer."Bank Message Type";
        GenJournalLine."Payment Message" := TempVendorPaymentBuffer."Payment Message";
        GenJournalLine."Payment Message 2" := TempVendorPaymentBuffer."Payment Message 2";
        GenJournalLine."Planned Payment Date" := TempVendorPaymentBuffer."Planned Payment Date";
    end;
}
