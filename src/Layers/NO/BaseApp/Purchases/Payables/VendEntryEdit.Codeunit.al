// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Sales.Receivables;

codeunit 113 "Vend. Entry-Edit"
{
    Permissions = TableData "Vendor Ledger Entry" = m,
                  TableData "Detailed Vendor Ledg. Entry" = m;
    TableNo = "Vendor Ledger Entry";

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
            VendLedgEntry.Validate("Payment Method Code", Rec."Payment Method Code");
            VendLedgEntry.Validate(KID, Rec.KID);
            VendLedgEntry."Payment Type Code Abroad" := Rec."Payment Type Code Abroad";
            VendLedgEntry."Specification (Norges Bank)" := Rec."Specification (Norges Bank)";
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
        OnBeforeVendLedgEntryModify(VendLedgEntry, Rec);
        VendLedgEntry.TestField("Entry No.", Rec."Entry No.");
        VendLedgEntry.Modify();
        OnRunOnAfterVendLedgEntryMofidy(VendLedgEntry);
        Rec := VendLedgEntry;
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

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterVendLedgEntryMofidy(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogFieldChanged(CurrVendorLedgerEntry: Record "Vendor Ledger Entry"; NewVendorLedgerEntry: Record "Vendor Ledger Entry"; var Changed: Boolean)
    begin
    end;
}

