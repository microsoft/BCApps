// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Environment.Configuration;

codeunit 7000126 "SII Purchase Subscribers"
{
    var
        SIIDuplicateExtDocNoTxt: Label 'A posted %1 with external document number %2 already exists for vendor %3. Because SII is enabled, the Spanish Tax Authority may reject this document as a duplicate (Factura Duplicada).', Comment = '%1 = Vendor Ledger Entry Document Type; %2 = External Document No.; %3 = Vendor No.';
        ShowSIIDuplicateVendLedgEntryTxt: Label 'Show the posted document';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Pay-to Vendor No.', true, false)]
    local procedure PurchHeaderOnAfterValidatePayToVendorNo(var Rec: Record "Purchase Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        Rec.Validate("ID Type", SIIManagement.GetPurchIDType(Rec."Pay-to Vendor No.", Rec."Correction Type", Rec."Corrected Invoice No."));
        SIIManagement.UpdateSIIInfoInPurchDoc(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitRecord', '', true, false)]
    local procedure PurchHeaderOnAfterInitRecord(var PurchHeader: Record "Purchase Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.UpdateSIIInfoInPurchDoc(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'VAT Prod. Posting Group', true, false)]
    local procedure PurchLineOnAfterValidateVATProdPostingGroup(var Rec: Record "Purchase Line")
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        SIISchemeCodeMgt.UpdatePurchSpecialSchemeCodeInPurchLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Vendor Invoice No.', true, false)]
    local procedure PurchHeaderOnAfterValidateVendorInvoiceNo(var Rec: Record "Purchase Header")
    begin
        NotifyIfSIIDuplicateExternalDocNo(Rec, Rec."Vendor Invoice No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Vendor Cr. Memo No.', true, false)]
    local procedure PurchHeaderOnAfterValidateVendorCrMemoNo(var Rec: Record "Purchase Header")
    begin
        NotifyIfSIIDuplicateExternalDocNo(Rec, Rec."Vendor Cr. Memo No.");
    end;

    local procedure NotifyIfSIIDuplicateExternalDocNo(PurchaseHeader: Record "Purchase Header"; ExternalDocNo: Code[35])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIManagement: Codeunit "SII Management";
    begin
        // Only relevant when SII is active. The per-user notification toggle is evaluated (and
        // seeded when missing) inside SendSIIDuplicateExtDocNoNotification, mirroring the standard flow.
        if ExternalDocNo = '' then
            exit;
        if PurchaseHeader."Pay-to Vendor No." = '' then
            exit;
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        // The standard OnValidate already warns for the SAME document type.
        // SII adds the cross-type case (Invoice vs. Credit Memo), which shares the same IDFactura for AEAT.
        if FindPostedDocWithSameExtDocNoDifferentType(PurchaseHeader, ExternalDocNo, VendorLedgerEntry) then
            SendSIIDuplicateExtDocNoNotification(PurchaseHeader, VendorLedgerEntry);
    end;

    local procedure FindPostedDocWithSameExtDocNoDifferentType(PurchaseHeader: Record "Purchase Header"; ExternalDocNo: Code[35]; var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        VendorMgt: Codeunit "Vendor Mgt.";
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("External Document No.");
        // Reuse the standard filter so 'Same Ext. Doc. No. in Diff. FY' (ES) is honored via OnAfterSetFilterForExternalDocNo.
        VendorMgt.SetFilterForExternalDocNo(
            VendorLedgerEntry, GetOppositeGenJnlDocType(PurchaseHeader), ExternalDocNo,
            PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Document Date");
        VendorLedgerEntry.SetRange("Do Not Send To SII", false);
        exit(VendorLedgerEntry.FindFirst());
    end;

    local procedure GetOppositeGenJnlDocType(PurchaseHeader: Record "Purchase Header"): Enum "Gen. Journal Document Type"
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Invoice/Order -> look for posted Credit Memos; Credit Memo/Return Order -> look for posted Invoices.
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::"Credit Memo",
            PurchaseHeader."Document Type"::"Return Order":
                exit(GenJournalLine."Document Type"::Invoice);
            else
                exit(GenJournalLine."Document Type"::"Credit Memo");
        end;
    end;

    local procedure SendSIIDuplicateExtDocNoNotification(PurchaseHeader: Record "Purchase Header"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        MyNotifications: Record "My Notifications";
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SIIDuplicateNotification: Notification;
    begin
        // Mirror the standard "already exists" notification guard: default-on when not yet seeded,
        // then create the missing My Notifications record before the final enable check.
        if not MyNotifications.IsEnabled(PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId()) then
            exit;
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId());
        if not PurchaseHeader.IsDocAlreadyExistNotificationEnabled() then
            exit;

        // Reuse the standard notification id + action so it shares one slot and respects the same user toggle.
        SIIDuplicateNotification.Id := PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId();
        SIIDuplicateNotification.Message :=
            StrSubstNo(SIIDuplicateExtDocNoTxt, VendorLedgerEntry."Document Type", VendorLedgerEntry."External Document No.", PurchaseHeader."Pay-to Vendor No.");
        SIIDuplicateNotification.Scope := NotificationScope::LocalScope;
        SIIDuplicateNotification.AddAction(ShowSIIDuplicateVendLedgEntryTxt, Codeunit::"Document Notifications", 'ShowVendorLedgerEntry');
        SIIDuplicateNotification.SetData(PurchaseHeader.FieldName("Document Type"), Format(PurchaseHeader."Document Type"));
        SIIDuplicateNotification.SetData(PurchaseHeader.FieldName("No."), PurchaseHeader."No.");
        SIIDuplicateNotification.SetData(VendorLedgerEntry.FieldName("Entry No."), Format(VendorLedgerEntry."Entry No."));
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
            SIIDuplicateNotification, PurchaseHeader.RecordId(), PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', true, false)]
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

    [EventSubscriber(ObjectType::Page, Page::"Posted Purch. Cr.Memo - Update", OnAfterRecordChanged, '', true, false)]
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


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Inv. Header - Edit", OnBeforePurchInvHeaderModify, '', true, false)]
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Inv. Header - Edit", OnRunOnAfterPurchInvHeaderEdit, '', true, false)]
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
