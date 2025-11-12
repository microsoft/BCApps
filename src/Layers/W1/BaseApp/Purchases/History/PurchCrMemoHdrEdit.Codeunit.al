// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

codeunit 1404 "Purch. Cr. Memo. Hdr. - Edit"
{
    Permissions = TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Copy(Rec);
        PurchCrMemoHdr.ReadIsolation(IsolationLevel::UpdLock);
        PurchCrMemoHdr.Find();
        PurchCrMemoHdr."Posting Description" := Rec."Posting Description";
        OnBeforePurchCrMemoHdrModify(PurchCrMemoHdr, Rec);
        PurchCrMemoHdr.TestField("No.", Rec."No.");
        PurchCrMemoHdr.Modify();
        Rec.Copy(PurchCrMemoHdr);

        UpdateVendorLedgerEntry(Rec);

        OnRunOnAfterPurchCrMemoHdrEdit(Rec);
    end;

    local procedure UpdateVendorLedgerEntry(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if not GetVendorLedgerEntry(VendorLedgerEntry, PurchCrMemoHdr) then
            exit;
        VendorLedgerEntry.Description := PurchCrMemoHdr."Posting Description";
        OnBeforeUpdateVendorLedgerEntryAfterSetValues(VendorLedgerEntry, PurchCrMemoHdr);
        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);
    end;

    local procedure GetVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."): Boolean
    begin
        if PurchCrMemoHdr."Vendor Ledger Entry No." = 0 then
            exit(false);
        VendorLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(VendorLedgerEntry.Get(PurchCrMemoHdr."Vendor Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHdrModify(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchCrMemoHdrRec: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendorLedgerEntryAfterSetValues(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPurchCrMemoHdrEdit(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}
