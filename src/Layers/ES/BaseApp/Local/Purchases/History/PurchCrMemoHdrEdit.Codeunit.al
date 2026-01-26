// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.EServices.EDocument;
using Microsoft.Purchases.Payables;

codeunit 10767 "Purch. Cr. Memo Hdr. - Edit"
{
    Permissions = TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr := Rec;
        PurchCrMemoHdr.LockTable();
        PurchCrMemoHdr.Find();
        PurchCrMemoHdr."Operation Description" := Rec."Operation Description";
        PurchCrMemoHdr."Operation Description 2" := Rec."Operation Description 2";
        PurchCrMemoHdr."Special Scheme Code" := Rec."Special Scheme Code";
        PurchCrMemoHdr."Cr. Memo Type" := Rec."Cr. Memo Type";
        PurchCrMemoHdr."Correction Type" := Rec."Correction Type";
        PurchCrMemoHdr."Corrected Invoice No." := Rec."Corrected Invoice No.";
        PurchCrMemoHdr."ID Type" := Rec."ID Type";
        PurchCrMemoHdr."Succeeded Company Name" := Rec."Succeeded Company Name";
        PurchCrMemoHdr."Succeeded VAT Registration No." := Rec."Succeeded VAT Registration No.";
        PurchCrMemoHdr."Posting Description" := Rec."Posting Description";
        OnRunOnBeforeTestFieldNo(PurchCrMemoHdr, Rec);
        OnBeforePurchCrMemoHdrModify(PurchCrMemoHdr, Rec);
        PurchCrMemoHdr.TestField("No.", Rec."No.");
        PurchCrMemoHdr.Modify();
        Rec := PurchCrMemoHdr;
        UpdateSIIDocUploadState(Rec);

        UpdateVendorLedgerEntry(Rec);
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

    local procedure UpdateSIIDocUploadState(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::"Credit Memo".AsInteger(),
             PurchCrMemoHdr."Posting Date",
             PurchCrMemoHdr."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignPurchCreditMemoType(PurchCrMemoHdr."Cr. Memo Type");
        SIIDocUploadState.AssignPurchSchemeCode(PurchCrMemoHdr."Special Scheme Code");
        SIISchemeCodeMgt.ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := PurchCrMemoHdr."ID Type";
        SIIDocUploadState."Succeeded Company Name" := PurchCrMemoHdr."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := PurchCrMemoHdr."Succeeded VAT Registration No.";
        SIIDocUploadState.GetCorrectionInfo(
          SIIDocUploadState."Corrected Doc. No.", SIIDocUploadState."Corr. Posting Date", SIIDocUploadState."Posting Date");
        SIIDocUploadState."Is Credit Memo Removal" := SIIDocUploadState.IsCreditMemoRemoval();
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTestFieldNo(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoHeaderRec: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHdrModify(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchCrMemoHdrRec: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendorLedgerEntryAfterSetValues(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}

