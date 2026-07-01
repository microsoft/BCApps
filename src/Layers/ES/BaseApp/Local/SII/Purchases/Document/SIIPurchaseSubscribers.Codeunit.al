// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 7000126 "SII Purchase Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Pay-to Vendor No.', false, false)]
    local procedure PurchHeaderOnAfterValidatePayToVendorNo(var Rec: Record "Purchase Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        Rec.Validate("ID Type", SIIManagement.GetPurchIDType(Rec."Pay-to Vendor No.", Rec."Correction Type", Rec."Corrected Invoice No."));
        SIIManagement.UpdateSIIInfoInPurchDoc(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitRecord', '', false, false)]
    local procedure PurchHeaderOnAfterInitRecord(var PurchHeader: Record "Purchase Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.UpdateSIIInfoInPurchDoc(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'VAT Prod. Posting Group', false, false)]
    local procedure PurchLineOnAfterValidateVATProdPostingGroup(var Rec: Record "Purchase Line")
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        SIISchemeCodeMgt.UpdatePurchSpecialSchemeCodeInPurchLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyVendLedgerEntryFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Invoice Type" := GenJournalLine."Purch. Invoice Type";
        VendorLedgerEntry."Cr. Memo Type" := GenJournalLine."Purch. Cr. Memo Type";
        VendorLedgerEntry."Special Scheme Code" := GenJournalLine."Purch. Special Scheme Code";
        VendorLedgerEntry."Correction Type" := GenJournalLine."Correction Type";
        VendorLedgerEntry."Corrected Invoice No." := GenJournalLine."Corrected Invoice No.";
        VendorLedgerEntry."Succeeded Company Name" := GenJournalLine."Succeeded Company Name";
        VendorLedgerEntry."Succeeded VAT Registration No." := GenJournalLine."Succeeded VAT Registration No.";
        VendorLedgerEntry."ID Type" := GenJournalLine."ID Type";
        VendorLedgerEntry."Do Not Send To SII" := GenJournalLine."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Purch. Cr.Memo - Update", OnAfterRecordChanged, '', false, false)]
    local procedure PurchCrMemoHeaderOnAfterRecordChanged(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; xPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          ((PurchCrMemoHeader."Operation Description" <> xPurchCrMemoHeader."Operation Description") or
          (PurchCrMemoHeader."Operation Description 2" <> xPurchCrMemoHeader."Operation Description 2") or
          (PurchCrMemoHeader."Special Scheme Code" <> xPurchCrMemoHeader."Special Scheme Code") or
          (PurchCrMemoHeader."Cr. Memo Type" <> xPurchCrMemoHeader."Cr. Memo Type") or
          (PurchCrMemoHeader."Corrected Invoice No." <> xPurchCrMemoHeader."Corrected Invoice No.") or
          (PurchCrMemoHeader."Correction Type" <> xPurchCrMemoHeader."Correction Type") or
          (PurchCrMemoHeader."ID Type" <> xPurchCrMemoHeader."ID Type") or
          (PurchCrMemoHeader."Succeeded Company Name" <> xPurchCrMemoHeader."Succeeded Company Name") or
          (PurchCrMemoHeader."Succeeded VAT Registration No." <> xPurchCrMemoHeader."Succeeded VAT Registration No."));
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Inv. Header - Edit", OnBeforePurchInvHeaderModify, '', false, false)]
    local procedure OnBeforePurchInvHeaderModify(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
        PurchInvHeader."Operation Description" := PurchInvHeaderRec."Operation Description";
        PurchInvHeader."Operation Description 2" := PurchInvHeaderRec."Operation Description 2";
        PurchInvHeader."Special Scheme Code" := PurchInvHeaderRec."Special Scheme Code";
        PurchInvHeader."Invoice Type" := PurchInvHeaderRec."Invoice Type";
        PurchInvHeader."ID Type" := PurchInvHeaderRec."ID Type";
        PurchInvHeader."Succeeded Company Name" := PurchInvHeaderRec."Succeeded Company Name";
        PurchInvHeader."Succeeded VAT Registration No." := PurchInvHeaderRec."Succeeded VAT Registration No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Inv. Header - Edit", OnRunOnAfterPurchInvHeaderEdit, '', false, false)]
    local procedure OnRunOnAfterPurchInvHeaderEdit(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        UpdateSIIDocUploadState(PurchInvHeader);
    end;

    local procedure UpdateSIIDocUploadState(PurchInvHeader: Record "Purch. Inv. Header")
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
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             PurchInvHeader."Posting Date",
             PurchInvHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignPurchInvoiceType(PurchInvHeader."Invoice Type");
        SIIDocUploadState.AssignPurchSchemeCode(PurchInvHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := PurchInvHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := PurchInvHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := PurchInvHeader."Succeeded VAT Registration No.";
        SIIDocUploadState.Modify();
    end;
}
