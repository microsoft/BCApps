// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.History;
using Microsoft.Sales.Receivables;

codeunit 113 "Vend. Entry-Edit"
{
    Permissions = TableData "Vendor Ledger Entry" = m,
                  TableData "Detailed Vendor Ledg. Entry" = m,
                  TableData "Purch. Inv. Header" = rm;
    TableNo = "Vendor Ledger Entry";

    var
        CalledFromPurchaseInvEdit: Boolean;

    trigger OnRun()
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, VendLedgEntry, DtldVendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        VendLedgEntry := Rec;
        VendLedgEntry.LockTable();
        VendLedgEntry.Find();
        VendLedgEntry."On Hold" := Rec."On Hold";

        if LogFieldChanged(VendLedgEntry, Rec) then
            BindSubscription(LedgEntryTrackChanges);

        VendLedgEntry."On Hold" := Rec."On Hold";
        if VendLedgEntry.Open then begin
            VendLedgEntry."Due Date" := Rec."Due Date";
            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
            OnRunOnBeforeDtldVendLedgEntryModifyAll(Rec, DtldVendLedgEntry, VendLedgEntry);
            DtldVendLedgEntry.ModifyAll("Initial Entry Due Date", Rec."Due Date");
            VendLedgEntry."Pmt. Discount Date" := Rec."Pmt. Discount Date";
            VendLedgEntry."Applies-to ID" := Rec."Applies-to ID";
            VendLedgEntry."Payment Method Code" := Rec."Payment Method Code";
            VendLedgEntry.Validate("Payment Reference", Rec."Payment Reference");
            VendLedgEntry.Validate("Remaining Pmt. Disc. Possible", Rec."Remaining Pmt. Disc. Possible");
            VendLedgEntry."Pmt. Disc. Tolerance Date" := Rec."Pmt. Disc. Tolerance Date";
            VendLedgEntry.Validate("Max. Payment Tolerance", Rec."Max. Payment Tolerance");
            VendLedgEntry.Validate("Accepted Payment Tolerance", Rec."Accepted Payment Tolerance");
            VendLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", Rec."Accepted Pmt. Disc. Tolerance");
            VendLedgEntry.Validate("Amount to Apply", Rec."Amount to Apply");
            VendLedgEntry.Validate("Applying Entry", Rec."Applying Entry");
            VendLedgEntry.Validate("Applies-to Ext. Doc. No.", Rec."Applies-to Ext. Doc. No.");
            VendLedgEntry.Validate("Message to Recipient", Rec."Message to Recipient");
            VendLedgEntry.Validate("Recipient Bank Account", Rec."Recipient Bank Account");
            VendLedgEntry.Validate("Remit-to Code", Rec."Remit-to Code");
        end;
        VendLedgEntry.Description := Rec.Description;
        VendLedgEntry.Validate("Exported to Payment File", Rec."Exported to Payment File");
        VendLedgEntry.Validate("Creditor No.", Rec."Creditor No.");
        VendLedgEntry.Validate("Dispute Status", Rec."Dispute Status");
        VendLedgEntry."Paid Int. Arrears Amount" := Rec."Paid Int. Arrears Amount";
        OnBeforeVendLedgEntryModify(VendLedgEntry, Rec);
        VendLedgEntry.TestField("Entry No.", Rec."Entry No.");
        VendLedgEntry.Modify();
        UpdatePurchInvHeader(VendLedgEntry);
        OnRunOnAfterVendLedgEntryModify(Rec, VendLedgEntry);
#if not CLEAN29
        OnRunOnAfterVendLedgEntryMofidy(VendLedgEntry);
#endif
        UpdatePurchInvHeader(VendLedgEntry);
        Rec := VendLedgEntry;
    end;

    procedure SetCalledFromPurchaseInvoice(CalledFromPurchaseInvEditSet: Boolean)
    begin
        CalledFromPurchaseInvEdit := CalledFromPurchaseInvEditSet;
    end;

    local procedure UpdatePurchInvHeader(UpdatePurchaseInvoiceVendLedgEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchaseInvoiceHeader(UpdatePurchaseInvoiceVendLedgEntry, CalledFromPurchaseInvEdit, IsHandled);
        if IsHandled then
            exit;

        if CalledFromPurchaseInvEdit then
            exit;
        if UpdatePurchaseInvoiceVendLedgEntry."Document Type" <> UpdatePurchaseInvoiceVendLedgEntry."Document Type"::Invoice then
            exit;
        if not PurchInvHeader.get(UpdatePurchaseInvoiceVendLedgEntry."Document No.") then
            exit;

        PurchInvHeader."Payment Reference" := UpdatePurchaseInvoiceVendLedgEntry."Payment Reference";
        PurchInvHeader."Payment Method Code" := UpdatePurchaseInvoiceVendLedgEntry."Payment Method Code";
        PurchInvHeader."Creditor No." := UpdatePurchaseInvoiceVendLedgEntry."Creditor No.";
        PurchInvHeader."Posting Description" := UpdatePurchaseInvoiceVendLedgEntry.Description;
        PurchInvHeader."Dispute Status" := UpdatePurchaseInvoiceVendLedgEntry."Dispute Status";
        PurchInvHeader.Modify(true);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";

    procedure SetOnHold(var VendorLedgerEntry: Record "Vendor Ledger Entry"; NewOnHold: Code[3])
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        xOnHold: Code[3];
    begin
        BindSubscription(LedgEntryTrackChanges);

        xOnHold := VendorLedgerEntry."On Hold";
        VendorLedgerEntry."On Hold" := NewOnHold;
        if xOnHold <> VendorLedgerEntry."On Hold" then
            VendorLedgerEntry.Modify();
    end;

    local procedure LogFieldChanged(CurrVendorLedgerEntry: Record "Vendor Ledger Entry"; NewVendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        Changed: Boolean;
    begin
        Changed :=
            (CurrVendorLedgerEntry.Description <> NewVendorLedgerEntry.Description) or
            (CurrVendorLedgerEntry."Due Date" <> NewVendorLedgerEntry."Due Date") or
            (CurrVendorLedgerEntry."Payment Method Code" <> NewVendorLedgerEntry."Payment Method Code") or
            (CurrVendorLedgerEntry."Message to Recipient" <> NewVendorLedgerEntry."Message to Recipient") or
            (CurrVendorLedgerEntry."Recipient Bank Account" <> NewVendorLedgerEntry."Recipient Bank Account") or
            (CurrVendorLedgerEntry."On Hold" <> NewVendorLedgerEntry."On Hold");
        OnAfterLogFieldChanged(CurrVendorLedgerEntry, NewVendorLedgerEntry, Changed);
        exit(Changed);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; FromVendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var VendorLedgerEntryRec: Record "Vendor Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailedVendLedgerEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeDtldVendLedgEntryModifyAll(FromVendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

#if not CLEAN29
    [Obsolete('Replaced by event OnRunOnAfterVendLedgEntryModify()', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterVendLedgEntryMofidy(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
#endif

    /// <summary>
    /// Raised after the vendor ledger entry has been modified.
    /// </summary>
    /// <param name="VendorLedgerEntryRec">The vendor ledger entry record passed to the codeunit.</param>
    /// <param name="VendorLedgerEntry">The modified vendor ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterVendLedgEntryModify(var VendorLedgerEntryRec: Record "Vendor Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogFieldChanged(CurrVendorLedgerEntry: Record "Vendor Ledger Entry"; NewVendorLedgerEntry: Record "Vendor Ledger Entry"; var Changed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchaseInvoiceHeader(var UpdatePurchaseInvoiceCustLedgerEntry: Record "Vendor Ledger Entry"; CalledFromPurchaseInvEdit: Boolean; var IsHandled: Boolean)
    begin
    end;
}

