// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 6403 "EDoc Prepare Cr. Memo Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Purch. Draft";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        PrepareInvoiceToApplyTo(EDocument);
        exit("E-Document Type"::"Purchase Credit Memo");
    end;

    /// <summary>
    /// Re-derives the invoice to apply to and its warnings after "Applies-to Vendor Inv. No." is changed on the draft, without preparing the rest of the draft again.
    /// </summary>
    internal procedure RefreshInvoiceToApplyTo(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ErrorMessage: Record "Error Message";
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Record ID", EDocumentPurchaseHeader.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Warning);
        ErrorMessage.SetRange("Field Number", EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."));
        ErrorMessage.DeleteAll();
        PrepareInvoiceToApplyTo(EDocument);
    end;

    local procedure PrepareInvoiceToApplyTo(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        FailureReason: Text;
        NoInvoiceStatedMsg: Label 'The credit note does not state the invoice it corrects.';
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit;
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then begin
            EDocumentPurchaseHeader."Applies-to Doc. No." := '';
            EDocumentPurchaseHeader.Modify();
            SuggestVendorOfReferencedInvoice(EDocument, EDocumentPurchaseHeader);
            exit;
        end;

        if EDocPurchDocHelper.ResolveInvoiceToApplyTo(EDocumentPurchaseHeader, FailureReason) then
            WarnIfInvoiceAlreadyCredited(EDocument, EDocumentPurchaseHeader)
        else begin
            if FailureReason = '' then
                FailureReason := NoInvoiceStatedMsg;
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                FailureReason + ' ' + EDocPurchDocHelper.GetNotAppliedOutcome(EDocumentPurchaseHeader."[BC] Vendor No."));
        end;
        EDocumentPurchaseHeader.Modify();
    end;

    /// <summary>
    /// One sentence for the draft page: whether the credit memo will be applied to an invoice when it is created, and the reason when it is not.
    /// </summary>
    internal procedure GetApplicationStatus(EDocument: Record "E-Document"): Text
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ErrorMessage: Record "Error Message";
        Status: TextBuilder;
        AppliedMsg: Label 'Will be applied to invoice %1.', Comment = '%1 = vendor invoice number';
        NotAppliedMsg: Label 'Will not be applied to a specific invoice.';
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit('');
        if EDocumentPurchaseHeader."Applies-to Doc. No." <> '' then
            Status.Append(StrSubstNo(AppliedMsg, EDocumentPurchaseHeader."Vendor Invoice No."))
        else
            Status.Append(NotAppliedMsg);

        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Record ID", EDocumentPurchaseHeader.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Warning);
        ErrorMessage.SetRange("Field Number", EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."));
        if ErrorMessage.FindSet() then
            repeat
                Status.Append(' ' + ErrorMessage.Message);
            until ErrorMessage.Next() = 0;
        exit(Status.ToText());
    end;

    local procedure WarnIfInvoiceAlreadyCredited(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        PayToVendorNo: Code[20];
        CurrencyCode: Code[10];
        RemainingLessThanCreditMsg: Label 'Invoice %1 (posted invoice %2) has a remaining amount of %3, which is less than this credit memo (%4). The invoice may already be credited or paid.', Comment = '%1 = vendor invoice number, %2 = posted invoice number, %3 = remaining amount, %4 = credit memo amount';
        PendingCreditMemoMsg: Label 'Purchase credit memo %1, which is not posted yet, is already set to apply to invoice %2 (posted invoice %3).', Comment = '%1 = purchase credit memo number, %2 = vendor invoice number, %3 = posted invoice number';
    begin
        PayToVendorNo := EDocPurchDocHelper.GetPayToVendorNo(EDocumentPurchaseHeader."[BC] Vendor No.");

        CurrencyCode := EDocumentPurchaseHeader."Currency Code";
        if GeneralLedgerSetup.Get() and (CurrencyCode = GeneralLedgerSetup."LCY Code") then
            CurrencyCode := '';
        VendorLedgerEntry.SetRange("Vendor No.", PayToVendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", EDocumentPurchaseHeader."Applies-to Doc. No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        if VendorLedgerEntry.FindFirst() then
            if (VendorLedgerEntry."Currency Code" = CurrencyCode) and (Abs(VendorLedgerEntry."Remaining Amount") < EDocumentPurchaseHeader.Total) then
                EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                    StrSubstNo(RemainingLessThanCreditMsg, EDocumentPurchaseHeader."Vendor Invoice No.", VendorLedgerEntry."Document No.", Abs(VendorLedgerEntry."Remaining Amount"), EDocumentPurchaseHeader.Total));

        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.SetRange("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.SetRange("Applies-to Doc. No.", EDocumentPurchaseHeader."Applies-to Doc. No.");
        PurchaseHeader.SetLoadFields("No.");
        if PurchaseHeader.FindFirst() then
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                StrSubstNo(PendingCreditMemoMsg, PurchaseHeader."No.", EDocumentPurchaseHeader."Vendor Invoice No.", EDocumentPurchaseHeader."Applies-to Doc. No."));
    end;

    local procedure SuggestVendorOfReferencedInvoice(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        Reference: Text;
        VendorNo: Code[20];
        VendorOfReferencedInvoiceMsg: Label 'The vendor could not be identified. Invoice %1, which this credit note refers to, was received from vendor %2 %3. Check whether this is the vendor of the credit note.', Comment = '%1 = invoice number, %2 = vendor number, %3 = vendor name';
    begin
        Reference := DelChr(EDocumentPurchaseHeader."Vendor Invoice No.", '<>', ' ');
        if (Reference = '') or EDocPurchaseDraftUtility.ReferencesSeveralInvoices(Reference) then
            exit;
        if StrLen(Reference) > MaxStrLen(VendorLedgerEntry."External Document No.") then
            exit;

        VendorLedgerEntry.SetLoadFields("Vendor No.", "Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetCurrentKey("External Document No.");
        VendorLedgerEntry.SetRange("External Document No.", Reference);
        if not FindSingleBuyFromVendor(VendorLedgerEntry, VendorNo) then
            exit;
        if StrLen(Reference) <= MaxStrLen(VendorLedgerEntry."Document No.") then begin
            VendorLedgerEntry.SetRange("External Document No.");
            VendorLedgerEntry.SetCurrentKey("Document No.");
            VendorLedgerEntry.SetRange("Document No.", Reference);
            if not FindSingleBuyFromVendor(VendorLedgerEntry, VendorNo) then
                exit;
        end;
        if VendorNo = '' then
            exit;

        Vendor.SetLoadFields(Name);
        if Vendor.Get(VendorNo) then
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                StrSubstNo(VendorOfReferencedInvoiceMsg, Reference, Vendor."No.", Vendor.Name));
    end;

    local procedure FindSingleBuyFromVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorNo: Code[20]): Boolean
    var
        EntryVendorNo: Code[20];
    begin
        if VendorLedgerEntry.FindSet() then
            repeat
                EntryVendorNo := VendorLedgerEntry."Buy-from Vendor No.";
                if EntryVendorNo = '' then
                    EntryVendorNo := VendorLedgerEntry."Vendor No.";
                if (VendorNo <> '') and (EntryVendorNo <> VendorNo) then
                    exit(false);
                VendorNo := EntryVendorNo;
            until VendorLedgerEntry.Next() = 0;
        exit(true);
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.OpenDraftPage(EDocument);
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.CleanUpDraft(EDocument);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    begin
        Vendor := PrepareDraftHelper.GetVendor(EDocument, Customizations);
    end;
}
