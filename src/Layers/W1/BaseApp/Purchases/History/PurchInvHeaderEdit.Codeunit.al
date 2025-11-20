// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

codeunit 1405 "Purch. Inv. Header - Edit"
{
    Permissions = TableData "Purch. Inv. Header" = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Copy(Rec);
        PurchInvHeader.ReadIsolation(IsolationLevel::UpdLock);
        PurchInvHeader.Find();
        PurchInvHeader."Payment Reference" := Rec."Payment Reference";
        PurchInvHeader."Payment Method Code" := Rec."Payment Method Code";
        PurchInvHeader."Creditor No." := Rec."Creditor No.";
        PurchInvHeader."Ship-to Code" := Rec."Ship-to Code";
        PurchInvHeader."Posting Description" := Rec."Posting Description";
        OnBeforePurchInvHeaderModify(PurchInvHeader, Rec);
        PurchInvHeader.TestField("No.", Rec."No.");
        PurchInvHeader.Modify();
        Rec.Copy(PurchInvHeader);

        UpdateVendorLedgerEntry(Rec);

        OnRunOnAfterPurchInvHeaderEdit(Rec);
    end;

    local procedure UpdateVendorLedgerEntry(PurchInvHeader: Record "Purch. Inv. Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if not GetVendorLedgerEntry(VendorLedgerEntry, PurchInvHeader) then
            exit;
        VendorLedgerEntry."Payment Method Code" := PurchInvHeader."Payment Method Code";
        VendorLedgerEntry."Payment Reference" := PurchInvHeader."Payment Reference";
        VendorLedgerEntry."Creditor No." := PurchInvHeader."Creditor No.";
        VendorLedgerEntry.Description := PurchInvHeader."Posting Description";
        OnBeforeUpdateVendorLedgerEntryAfterSetValues(VendorLedgerEntry, PurchInvHeader);
        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);
    end;

    local procedure GetVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        if PurchInvHeader."Vendor Ledger Entry No." = 0 then
            exit(false);
        VendorLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderModify(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendorLedgerEntryAfterSetValues(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPurchInvHeaderEdit(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;
}

