// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using System.Utilities;

#pragma warning disable AS0088
codeunit 7000095 "Purch. Corrective Doc. Subscr."
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnValidatePayToVendorNoOnAfterResetPurchLines', '', true, false)]
    local procedure OnValidatePayToVendorNoOnAfterResetPurchLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    begin
        if xPurchaseHeader."Pay-to Vendor No." <> PurchaseHeader."Pay-to Vendor No." then
            PurchaseHeader."Corrected Invoice No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnCopyFromGenJnlLineOnAfterCopyFields', '', true, false)]
    local procedure OnCopyFromGenJnlLineOnAfterCopyFields(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Correction Type" := GenJournalLine."Correction Type";
        VendorLedgerEntry."Corrected Invoice No." := GenJournalLine."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice", 'OnPostLedgerEntryOnCopyHeaderFields', '', true, false)]
    local procedure OnPostLedgerEntryOnCopyHeaderFields(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header")
    begin
        GenJnlLine."Correction Type" := PurchHeader."Correction Type";
        GenJnlLine."Corrected Invoice No." := PurchHeader."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", 'OnCopyInvoiceToCreditMemoHeader', '', true, false)]
    local procedure OnCopyInvoiceToCreditMemoHeader(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchaseHeader."Corrected Invoice No." := PurchInvHeader."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnCheckCorrectedInvoiceNo', '', true, false)]
    local procedure OnCheckCorrectedInvoiceNo(var PurchaseHeader: Record "Purchase Header"; PurchSetup: Record "Purchases & Payables Setup")
    var
        PurchPost: Codeunit "Purch.-Post";
        ConfirmManagement: Codeunit "Confirm Management";
        MissingCorrectedInvoiceQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        PostingCancelledErr: Label 'The posting process has been cancelled by the user.';
        CorrectiveInvoiceLbl: Label 'Corrective Invoice';
    begin
        if PurchaseHeader.IsCreditDocType() and PurchaseHeader.Invoice then begin
            if PurchSetup."Correct. Doc. No. Mandatory" then
                PurchaseHeader.TestField("Corrected Invoice No.")
            else begin
                if PurchaseHeader."Correction Type" = PurchaseHeader."Correction Type"::Removal then
                    PurchaseHeader.TestField("Corrected Invoice No.");
                PurchPost.OnCheckCorrectedInvoiceNoOnBeforeConfirm(PurchaseHeader);
                if PurchaseHeader."Corrected Invoice No." = '' then
                    if not ConfirmManagement.GetResponseOrDefault(MissingCorrectedInvoiceQst, false) then
                        Error(PostingCancelledErr);
            end;
            if (PurchaseHeader."Corrected Invoice No." <> '') and (PurchaseHeader."Posting Description" = '') then
                PurchaseHeader."Posting Description" := Format(CorrectiveInvoiceLbl) + ' ' + PurchaseHeader."No."
        end;
    end;
}
