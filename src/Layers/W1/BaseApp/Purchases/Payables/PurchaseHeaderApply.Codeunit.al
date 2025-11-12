// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Document;

codeunit 402 "Purchase Header Apply"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        PurchHeader.Copy(Rec);
        PayToVendorNo := PurchHeader."Pay-to Vendor No.";
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", PayToVendorNo);
        VendLedgEntry.SetRange(Open, true);
        OnRunOnAfterFilterVendLedgEntry(VendLedgEntry, PurchHeader);
        if PurchHeader."Applies-to ID" = '' then
            PurchHeader."Applies-to ID" := PurchHeader."No.";
        if PurchHeader."Applies-to ID" = '' then
            Error(
              Text000,
              PurchHeader.FieldCaption("No."), PurchHeader.FieldCaption("Applies-to ID"));
        ApplyVendEntries.SetPurch(PurchHeader, VendLedgEntry, PurchHeader.FieldNo("Applies-to ID"));
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        OK := ApplyVendEntries.RunModal() = ACTION::LookupOK;
        Clear(ApplyVendEntries);
        if not OK then
            exit;
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", PayToVendorNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Applies-to ID", PurchHeader."Applies-to ID");
        OnRunOnBeforeVendLedgEntryFindFirst(VendLedgEntry);
        if VendLedgEntry.FindFirst() then begin
            PurchHeader."Applies-to Doc. Type" := PurchHeader."Applies-to Doc. Type"::" ";
            PurchHeader."Applies-to Doc. No." := '';
        end else
            PurchHeader."Applies-to ID" := '';

        PurchHeader.Modify();

        OnAfterOnRun(PurchHeader);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1 or %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
        PayToVendorNo: Code[20];
        OK: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterFilterVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeVendLedgEntryFindFirst(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

