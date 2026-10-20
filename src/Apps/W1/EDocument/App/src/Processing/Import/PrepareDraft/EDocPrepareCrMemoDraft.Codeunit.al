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
    /// Re-derives Applies-to Doc. No. and its warnings after "Applies-to Vendor Inv. No." is changed on the draft, without preparing the rest of the draft again.
    /// </summary>
    internal procedure RefreshInvoiceToApplyTo(EDocument: Record "E-Document")
    begin
        ClearInvoiceWarnings(EDocument);
        PrepareInvoiceToApplyTo(EDocument);
    end;

    /// <summary>
    /// Fails when the invoice the user selected in Applies-to Doc. No. is not an open posted invoice of the draft's vendor.
    /// </summary>
    internal procedure ValidateInvoiceToApplyTo(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
    begin
        if EDocumentPurchaseHeader."Applies-to Doc. No." = '' then
            exit;
        EDocPurchDocHelper.TestOpenInvoiceToApplyTo(
            EDocumentPurchaseHeader."[BC] Vendor No.", EDocumentPurchaseHeader."Currency Code",
            CopyStr(EDocumentPurchaseHeader."Applies-to Doc. No.", 1, 20));
    end;

    /// <summary>
    /// Replaces the invoice warnings after the user selected the invoice in Applies-to Doc. No.
    /// </summary>
    internal procedure RefreshWarningsForSelectedInvoice(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        ClearInvoiceWarnings(EDocument);
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."Applies-to Doc. No." <> '' then
            WarnIfInvoiceAlreadyCredited(EDocument, EDocumentPurchaseHeader)
        else
            if EDocumentPurchaseHeader."Several Invoices Referenced" then
                EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                    EDocPurchDocHelper.GetSeveralInvoicesMatchWarning())
            else
                EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                    EDocPurchDocHelper.GetNotAppliedOutcome(EDocumentPurchaseHeader."[BC] Vendor No."));
    end;

    /// <summary>
    /// Lets the user select an open posted invoice of the draft's vendor to apply the credit memo to.
    /// When the invoice reference matches several invoices, only those are offered.
    /// </summary>
    internal procedure LookupInvoiceToApplyTo(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var Text: Text): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorLedgerEntries: Page "Vendor Ledger Entries";
    begin
        EDocPurchDocHelper.FilterOpenInvoicesToApplyTo(EDocumentPurchaseHeader."[BC] Vendor No.", EDocumentPurchaseHeader."Vendor Invoice No.", VendorLedgerEntry);
        VendorLedgerEntries.SetTableView(VendorLedgerEntry);
        VendorLedgerEntries.LookupMode(true);
        if VendorLedgerEntries.RunModal() <> Action::LookupOK then
            exit(false);
        VendorLedgerEntries.GetRecord(VendorLedgerEntry);
        Text := VendorLedgerEntry."Document No.";
        exit(true);
    end;

    local procedure PrepareInvoiceToApplyTo(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        FailureReason: Text;
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit;
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then begin
            EDocumentPurchaseHeader."Applies-to Doc. No." := '';
            EDocumentPurchaseHeader.Modify();
            WarnWithVendorOfReferencedInvoice(EDocument, EDocumentPurchaseHeader);
            exit;
        end;

        // A credit note that states several invoices is not applied to any of them; the user selects the invoice.
        if EDocumentPurchaseHeader."Several Invoices Referenced" then begin
            EDocumentPurchaseHeader."Applies-to Doc. No." := '';
            EDocImpSessionTelemetry.SetText('AppliesToResolution', 'SeveralReferenced');
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                EDocPurchDocHelper.GetSeveralInvoicesMatchWarning());
        end else
            if EDocPurchDocHelper.ResolveInvoiceToApplyTo(EDocumentPurchaseHeader, FailureReason) then
                WarnIfInvoiceAlreadyCredited(EDocument, EDocumentPurchaseHeader)
            else begin
                if FailureReason = '' then
                    FailureReason := EDocPurchDocHelper.GetNotAppliedOutcome(EDocumentPurchaseHeader."[BC] Vendor No.");
                EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."), FailureReason);
            end;
        EDocumentPurchaseHeader.Modify();
    end;

    /// <summary>
    /// The warnings about the invoice to apply to, shown below Applies-to Doc. No. on the draft.
    /// </summary>
    internal procedure GetInvoiceWarnings(EDocument: Record "E-Document") Warnings: List of [Text]
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ErrorMessage: Record "Error Message";
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit;
        FilterInvoiceWarnings(EDocument, EDocumentPurchaseHeader, ErrorMessage);
        ErrorMessage.SetLoadFields(Message);
        if ErrorMessage.FindSet() then
            repeat
                Warnings.Add(ErrorMessage.Message);
            until ErrorMessage.Next() = 0;
    end;

    local procedure ClearInvoiceWarnings(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        ErrorMessage: Record "Error Message";
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        FilterInvoiceWarnings(EDocument, EDocumentPurchaseHeader, ErrorMessage);
        ErrorMessage.DeleteAll();
    end;

    local procedure FilterInvoiceWarnings(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var ErrorMessage: Record "Error Message")
    begin
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Record ID", EDocumentPurchaseHeader.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Warning);
        ErrorMessage.SetRange("Field Number", EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."));
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
        RemainingLessThanCreditMsg: Label 'The credit memo amount exceeds the remaining amount on the selected invoice. The credit memo won''t be fully applied to this invoice. Review the application and adjust it if needed.';
        PendingCreditMemoMsg: Label 'Unposted purchase credit memo %1 is already set to apply to this invoice. Check for duplicate credits.', Comment = '%1 = purchase credit memo number';
    begin
        PayToVendorNo := EDocPurchDocHelper.GetPayToVendorNo(EDocumentPurchaseHeader."[BC] Vendor No.");

        CurrencyCode := EDocumentPurchaseHeader."Currency Code";
        if GeneralLedgerSetup.Get() and (CurrencyCode = GeneralLedgerSetup."LCY Code") then
            CurrencyCode := '';
        VendorLedgerEntry.SetRange("Vendor No.", PayToVendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", EDocumentPurchaseHeader."Applies-to Doc. No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetLoadFields("Currency Code");
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        if VendorLedgerEntry.FindFirst() then
            if (VendorLedgerEntry."Currency Code" = CurrencyCode) and (Abs(VendorLedgerEntry."Remaining Amount") < EDocumentPurchaseHeader.Total) then
                EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."), RemainingLessThanCreditMsg);

        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.SetRange("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.SetRange("Applies-to Doc. No.", EDocumentPurchaseHeader."Applies-to Doc. No.");
        PurchaseHeader.SetLoadFields("No.");
        if PurchaseHeader.FindFirst() then
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Vendor Invoice No."),
                StrSubstNo(PendingCreditMemoMsg, PurchaseHeader."No."));
    end;

    local procedure WarnWithVendorOfReferencedInvoice(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        Reference: Text;
        VendorNo: Code[20];
        VendorOfReferencedInvoiceMsg: Label 'Invoice %1 on the credit note was received from vendor %2 %3. Check whether the credit note is from the same vendor.', Comment = '%1 = invoice number, %2 = vendor number, %3 = vendor name';
    begin
        Reference := DelChr(EDocumentPurchaseHeader."Vendor Invoice No.", '<>', ' ');
        if Reference = '' then
            exit;
        if StrLen(Reference) > MaxStrLen(VendorLedgerEntry."External Document No.") then
            exit;

        VendorLedgerEntry.SetLoadFields("Vendor No.", "Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("External Document No.", Reference);
        if not FindSingleBuyFromVendor(VendorLedgerEntry, VendorNo) then
            exit;
        if StrLen(Reference) <= MaxStrLen(VendorLedgerEntry."Document No.") then begin
            VendorLedgerEntry.SetRange("External Document No.");
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
