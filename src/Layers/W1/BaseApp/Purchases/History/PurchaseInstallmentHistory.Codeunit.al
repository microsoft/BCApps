// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;

codeunit 8848 "Purchase Installment History"
{
    Access = Internal;
    Permissions = tabledata "Vendor Ledger Entry" = rm,
                  tabledata "Detailed Vendor Ledg. Entry" = rm;

    var
        EditErr: Label 'Changing posted installment payment conditions is not supported.';
        AutomaticApplicationErr: Label 'Automatic application to global installments is supported only for vendor payments. Select other applications using Applies-to ID.';
        ReconciliationSelectionErr: Label 'Invoice %1 has more than one open installment. Select the vendor ledger entries manually on payment reconciliation statement line %2.', Comment = '%1 = Invoice number, %2 = Statement line number';
        IncompleteBackfillMsg: Label 'Installment invoice grouping could not be completed because a posted invoice or vendor ledger anchor is missing or inconsistent. The upgrade tag was not set.', Locked = true;

    internal procedure SetInvoiceGroup(PlanID: Guid; InvoiceEntryNo: BigInteger)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AnchorEntry: Record "Vendor Ledger Entry";
    begin
        AnchorEntry.Get(InvoiceEntryNo);
        AnchorEntry.TestField("Installment Plan ID");
        AnchorEntry.TestField("Installment Plan ID", PlanID);
        VendorLedgerEntry.SetRange("Installment Plan ID", PlanID);
        DetailedVendorLedgEntry.SetFilter("Invoice Entry No.", '<>%1', InvoiceEntryNo);
        if VendorLedgerEntry.FindSet(true) then
            repeat
                DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                DetailedVendorLedgEntry.ModifyAll("Invoice Entry No.", InvoiceEntryNo);
                if VendorLedgerEntry."Invoice Entry No." <> InvoiceEntryNo then begin
                    VendorLedgerEntry."Invoice Entry No." := InvoiceEntryNo;
                    VendorLedgerEntry.Modify();
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    internal procedure BackfillInvoiceGroups() Complete: Boolean
    var
        Plan: Record "Purchase Installment Plan";
    begin
        Complete := true;
        Plan.SetRange(Status, Plan.Status::Posted);
        if Plan.FindSet() then
            repeat
                if not BackfillInvoiceGroup(Plan) then
                    Complete := false;
            until Plan.Next() = 0;
        if not Complete then
            Session.LogMessage('PurchaseInstallmentGroupBackfillIncomplete', IncompleteBackfillMsg, Verbosity::Warning,
                DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'AL SaaS Upgrade');
    end;

    local procedure BackfillInvoiceGroup(Plan: Record "Purchase Installment Plan"): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        AnchorEntry: Record "Vendor Ledger Entry";
    begin
        if IsNullGuid(Plan.ID) then
            exit(false);
        if not PurchInvHeader.Get(Plan."Posted Invoice No.") then
            exit(false);
        if (PurchInvHeader.SystemId <> Plan."Posted Invoice SystemId") or
           (PurchInvHeader."Installment Plan ID" <> Plan.ID)
        then
            exit(false);
        if not AnchorEntry.Get(PurchInvHeader."Vendor Ledger Entry No.") then
            exit(false);
        if AnchorEntry."Installment Plan ID" <> Plan.ID then
            exit(false);
        SetInvoiceGroup(Plan.ID, AnchorEntry."Entry No.");
        exit(true);
    end;

    procedure ShowSchedule(PurchInvHeader: Record "Purch. Inv. Header")
    var
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
    begin
        Plan.Get(PurchInvHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice SystemId", PurchInvHeader.SystemId);
        PlanLine.FilterGroup(2);
        PlanLine.SetRange("Plan ID", Plan.ID);
        PlanLine.FilterGroup(0);
        Page.Run(Page::"Posted Purch. Inst. Schedule", PlanLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure InitializeVendorGroup(var Rec: Record "Vendor Ledger Entry")
    begin
        if not Rec.IsTemporary() then
            Rec."Invoice Entry No." := Rec."Entry No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure InitializeDetailedGroup(var Rec: Record "Detailed Vendor Ledg. Entry")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        Rec."Invoice Entry No." := Rec."Vendor Ledger Entry No.";
        if (Rec."Entry Type" = Rec."Entry Type"::"Initial Entry") or
           (Rec."Initial Document Type" <> Rec."Initial Document Type"::Invoice)
        then
            exit;
        VendorLedgerEntry.SetLoadFields("Invoice Entry No.");
        if VendorLedgerEntry.Get(Rec."Vendor Ledger Entry No.") then
            if VendorLedgerEntry."Invoice Entry No." <> 0 then
                Rec."Invoice Entry No." := VendorLedgerEntry."Invoice Entry No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckVendorConditions(var Rec: Record "Vendor Ledger Entry")
    var
        SavedEntry: Record "Vendor Ledger Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        SavedEntry.Get(Rec."Entry No.");
        if IsNullGuid(SavedEntry."Installment Plan ID") then
            exit;
        if (Rec."Installment Plan ID" <> SavedEntry."Installment Plan ID") or
           (Rec."Installment No." <> SavedEntry."Installment No.") or
           (Rec."No. of Installments" <> SavedEntry."No. of Installments") or
           (Rec."Due Date" <> SavedEntry."Due Date") or
           (Rec."Pmt. Discount Date" <> SavedEntry."Pmt. Discount Date") or
           (Rec."Pmt. Disc. Tolerance Date" <> SavedEntry."Pmt. Disc. Tolerance Date") or
           (Rec."Payment Method Code" <> SavedEntry."Payment Method Code") or
           (Rec."Payment Reference" <> SavedEntry."Payment Reference")
        then
            Error(EditErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckInvoiceConditions(var Rec: Record "Purch. Inv. Header")
    var
        SavedInvoice: Record "Purch. Inv. Header";
    begin
        if Rec.IsTemporary() then
            exit;
        SavedInvoice.Get(Rec."No.");
        if IsNullGuid(SavedInvoice."Installment Plan ID") then
            exit;
        if (Rec."Installment Plan ID" <> SavedInvoice."Installment Plan ID") or
           (Rec."Due Date" <> SavedInvoice."Due Date") or
           (Rec."Payment Terms Code" <> SavedInvoice."Payment Terms Code") or
           (Rec."Payment Discount %" <> SavedInvoice."Payment Discount %") or
           (Rec."Pmt. Discount Date" <> SavedInvoice."Pmt. Discount Date") or
           (Rec."Payment Method Code" <> SavedInvoice."Payment Method Code") or
           (Rec."Payment Reference" <> SavedInvoice."Payment Reference")
        then
            Error(EditErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vend. Entry-Edit", 'OnBeforeVendLedgEntryModify', '', false, false)]
#pragma warning disable AA0150
    local procedure CheckVendorEdit(var VendLedgEntry: Record "Vendor Ledger Entry"; FromVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        if not IsNullGuid(FromVendLedgEntry."Installment Plan ID") then
            CheckVendorConditions(VendLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vend. Entry-Edit", 'OnBeforeUpdatePurchaseInvoiceHeader', '', false, false)]
    local procedure SkipInvoiceSummaryUpdate(var UpdatePurchaseInvoiceVendorLedgerEntry: Record "Vendor Ledger Entry"; CalledFromPurchaseInvoiceEdit: Boolean; var IsHandled: Boolean)
    begin
        if not IsNullGuid(UpdatePurchaseInvoiceVendorLedgerEntry."Installment Plan ID") then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Inv. Header - Edit", 'OnBeforePurchInvHeaderModify', '', false, false)]
    local procedure CheckPostedInvoiceEdit(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
        CheckInvoiceConditions(PurchInvHeader);
    end;
#pragma warning restore AA0150

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert', '', false, false)]
    local procedure CheckAutomaticApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if IsNullGuid(VendorLedgerEntry."Installment Plan ID") or
           (GenJournalLine."Applies-to ID" <> '') or (GenJournalLine."Applies-to Doc. No." <> '')
        then
            exit;
        if not IsAutomaticPayment(GenJournalLine) then
            Error(AutomaticApplicationErr);
        VendorLedgerEntry.TestField("Invoice Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnBeforeExit', '', false, false)]
#pragma warning disable AA0150
    local procedure OrderAutomaticInstallmentApplication(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    var
        TempInstallmentEntry: Record "Vendor Ledger Entry" temporary;
        EmptyGuid: Guid;
    begin
        if not IsAutomaticPayment(GenJournalLine) then
            exit;
        TempInstallmentEntry.Copy(TempOldVendLedgEntry, true);
        TempInstallmentEntry.SetFilter("Installment Plan ID", '<>%1', EmptyGuid);
        if TempInstallmentEntry.IsEmpty() then
            exit;
        TempOldVendLedgEntry.SetCurrentKey(
            "Vendor No.", "Applies-to ID", Open, Positive, "Due Date", "Invoice Entry No.", "Installment No.");
    end;
#pragma warning restore AA0150

    local procedure IsAutomaticPayment(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        exit((GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) and
             (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment) and
             (GenJournalLine.Amount > 0) and IsNullGuid(GenJournalLine."Installment Plan ID") and
             (GenJournalLine."Applies-to ID" = '') and (GenJournalLine."Applies-to Doc. No." = ''));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Applied Payment Entry", 'OnApplyFromBankStmtMatchingBufOnBeforeInsert', '', false, false)]
    local procedure CheckAutomaticReconciliation(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankStmtMatchingBuffer: Record "Bank Statement Matching Buffer"; EntryNo: BigInteger)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OpenInstallment: Record "Vendor Ledger Entry";
    begin
        if (BankStmtMatchingBuffer."Account Type" <> BankStmtMatchingBuffer."Account Type"::Vendor) or (EntryNo <= 0) then
            exit;
        VendorLedgerEntry.Get(EntryNo);
        if IsNullGuid(VendorLedgerEntry."Installment Plan ID") then
            exit;
        OpenInstallment.SetRange("Installment Plan ID", VendorLedgerEntry."Installment Plan ID");
        OpenInstallment.SetRange(Open, true);
        if OpenInstallment.Find('-') then
            if OpenInstallment.Next() <> 0 then
                Error(ReconciliationSelectionErr, VendorLedgerEntry."Document No.", BankAccReconLine."Statement Line No.");
    end;
}
