// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Shared logic for creating BC purchase documents (invoices and credit memos) from e-document draft data.
/// </summary>
codeunit 6402 "E-Doc. Purch. Doc. Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Dimension Set Tree Node" = im,
                  tabledata "Dimension Set Entry" = im;

    procedure CreatePurchaseLineFromDraft(PurchaseHeader: Record "Purchase Header"; EDocumentPurchaseLine: Record "E-Document Purchase Line"; HasTotalDiscount: Boolean; LineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        EDocRecordLink: Record "E-Doc. Record Link";
        EDocumentPurchaseHistMapping: Codeunit "E-Doc. Purchase Hist. Mapping";
        DimensionManagement: Codeunit DimensionManagement;
        PurchaseLineCombinedDimensions: array[10] of Integer;
        GlobalDim1, GlobalDim2 : Code[20];
    begin
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LineNo;
        PurchaseLine.Type := EDocumentPurchaseLine."[BC] Purchase Line Type";
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("No."), EDocumentPurchaseLine."[BC] Purchase Type No.");
        if EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" <> '' then
            ValidateFieldWithContext(
                PurchaseLine, PurchaseLine.FieldNo("VAT Prod. Posting Group"), EDocumentPurchaseLine."[BC] VAT Prod. Posting Group");
        if (PurchaseLine.Type = PurchaseLine.Type::"G/L Account") and HasTotalDiscount then
            ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Allow Invoice Disc."), true);
        PurchaseLine.Description := EDocumentPurchaseLine.Description;

        if EDocumentPurchaseLine."[BC] Item Reference No." <> '' then
            ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Item Reference No."), EDocumentPurchaseLine."[BC] Item Reference No.");

        if EDocumentPurchaseLine."[BC] Variant Code" <> '' then
            ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Variant Code"), EDocumentPurchaseLine."[BC] Variant Code");
        if EDocumentPurchaseLine."[BC] Unit of Measure" <> '' then
            ValidateFieldWithContext(
                PurchaseLine, PurchaseLine.FieldNo("Unit of Measure Code"), CopyStr(EDocumentPurchaseLine."[BC] Unit of Measure", 1, MaxStrLen(PurchaseLine."Unit of Measure Code")));

        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo(Quantity), EDocumentPurchaseLine.Quantity);
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Direct Unit Cost"), EDocumentPurchaseLine."Unit Price");
        if DiscountFollowsLineDirection(PurchaseLine, EDocumentPurchaseLine."Total Discount") then
            ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Line Discount Amount"), EDocumentPurchaseLine."Total Discount");
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Deferral Code"), EDocumentPurchaseLine."[BC] Deferral Code");

        PurchaseLineCombinedDimensions[1] := PurchaseLine."Dimension Set ID";
        PurchaseLineCombinedDimensions[2] := EDocumentPurchaseLine."[BC] Dimension Set ID";
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Dimension Set ID"), DimensionManagement.GetCombinedDimensionSetID(PurchaseLineCombinedDimensions, GlobalDim1, GlobalDim2));
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Shortcut Dimension 1 Code"), EDocumentPurchaseLine."[BC] Shortcut Dimension 1 Code");
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Shortcut Dimension 2 Code"), EDocumentPurchaseLine."[BC] Shortcut Dimension 2 Code");
        EDocumentPurchaseHistMapping.ApplyAdditionalFieldsFromHistoryToPurchaseLine(EDocumentPurchaseLine, PurchaseLine);
        PurchaseLine.Insert();
        EDocRecordLink.InsertEDocumentLineLink(EDocumentPurchaseLine, PurchaseLine);
    end;

    /// <summary>
    /// A line discount is carried over only when it reduces the line in the line's own direction, which is the only discount Business Central accepts as a percentage between 0 and 100.
    /// </summary>
    local procedure DiscountFollowsLineDirection(PurchaseLine: Record "Purchase Line"; LineDiscountAmount: Decimal): Boolean
    begin
        exit(LineDiscountAmount * PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" > 0);
    end;

    procedure ValidateFieldWithContext(var Rec: Record "Purchase Header"; FieldNo: Integer; Value: Variant)
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ValidateFieldWithContext(VariantRec, FieldNo, Value);
        Rec := VariantRec;
    end;

    procedure ValidateFieldWithContext(var Rec: Record "Purchase Line"; FieldNo: Integer; Value: Variant)
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ValidateFieldWithContext(VariantRec, FieldNo, Value);
        Rec := VariantRec;
    end;

    local procedure ValidateFieldWithContext(var RecVariant: Variant; FieldNo: Integer; Value: Variant)
    var
        EDocImportErrorContext: Codeunit "E-Doc. Import Error Context";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(RecVariant);
        FldRef := RecRef.Field(FieldNo);
        EDocImportErrorContext.OnValidateFieldWithContext(FldRef.Caption());
        FldRef.Validate(Value);
        RecRef.SetTable(RecVariant);
    end;

    procedure AllDraftLinesHaveTypeAndNumber(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Boolean
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseLine.SetLoadFields("[BC] Purchase Line Type", "[BC] Purchase Type No.");
        EDocumentPurchaseLine.ReadIsolation(IsolationLevel::ReadCommitted);
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        if not EDocumentPurchaseLine.FindSet() then
            exit(true);
        repeat
            if EDocumentPurchaseLine."[BC] Purchase Line Type" = EDocumentPurchaseLine."[BC] Purchase Line Type"::" " then
                exit(false);
            if EDocumentPurchaseLine."[BC] Purchase Type No." = '' then
                exit(false);
        until EDocumentPurchaseLine.Next() = 0;
        exit(true);
    end;

    [TryFunction]
    procedure TryValidateDocumentTotals(PurchaseHeader: Record "Purchase Header")
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.CheckDocumentTotalAmounts(PurchaseHeader);
    end;

    procedure GetLastPurchaseLineNo(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetLoadFields("Line No.");
        PurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No.");
    end;

    procedure FinalizeCreatedDocument(EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);

        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
        PurchaseHeader."Doc. Amount Incl. VAT" := EDocumentPurchaseHeader.Total;
        PurchaseHeader."Doc. Amount VAT" := EDocumentPurchaseHeader."Total VAT";
        PurchaseHeader.TestField("No.");
        PurchaseHeader."E-Document Link" := EDocument.SystemId;
        PurchaseHeader.Modify();

        DocumentAttachmentMgt.CopyAttachments(EDocument, PurchaseHeader);
        DocumentAttachmentMgt.DeleteAttachedDocuments(EDocument);

        EDocImpSessionTelemetry.SetBool('Totals Validation', TryValidateDocumentTotals(PurchaseHeader));
    end;

    procedure ApplyVATDifferenceToLines(PurchaseHeader: Record "Purchase Header"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        LineAmount: Decimal;
        TotalLineAmount, VATDiffRemainder, VATDiffForLine : Decimal;
        AppliedVATAmountDiff: Decimal;
    begin
        AppliedVATAmountDiff := EDocumentPurchaseHeader.GetAppliedVATAmountDiff();
        if AppliedVATAmountDiff = 0 then
            exit;

        if PurchaseHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchaseHeader."Currency Code");

        TotalLineAmount := ComputeTotalLineAmount(EDocumentPurchaseHeader."E-Document Entry No.", Currency."Amount Rounding Precision");
        if TotalLineAmount = 0 then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        if not PurchaseLine.FindSet() then
            exit;

        VATDiffRemainder := 0;
        repeat
            LineAmount := PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount";
            if LineAmount <> 0 then begin
                VATDiffForLine := VATDiffRemainder + AppliedVATAmountDiff * LineAmount / TotalLineAmount;
                PurchaseLine.Validate("VAT Difference", Round(VATDiffForLine, Currency."Amount Rounding Precision"));
                VATDiffRemainder := VATDiffForLine - PurchaseLine."VAT Difference";
                PurchaseLine.Modify(true);
            end;
        until PurchaseLine.Next() = 0;
    end;

    procedure RevertCreatedDocument(EDocument: Record "E-Document")
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
    begin
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        if not PurchaseHeader.FindFirst() then
            exit;

        DocumentAttachmentMgt.CopyAttachments(PurchaseHeader, EDocument);
        DocumentAttachmentMgt.DeleteAttachedDocuments(PurchaseHeader);

        Clear(PurchaseHeader."E-Document Link");
        PurchaseHeader.Modify();
    end;

    procedure ApplyDefaultPostingDateFromSetup(var PurchaseHeader: Record "Purchase Header"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.GetRecordOnce();
        if (PurchasesPayablesSetup."E-Doc. Def. Posting Date" <> PurchasesPayablesSetup."E-Doc. Def. Posting Date"::"Document Date") then
            exit;
        if EDocumentPurchaseHeader."Document Date" = 0D then
            exit;
        PurchaseHeader.Validate("Posting Date", EDocumentPurchaseHeader."Document Date");
    end;

    procedure SetNormalReverseChargeFilter(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Calculation Type", '%1|%2',
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    /// <summary>
    /// Finds the one open posted invoice of the pay-to vendor that Reference identifies, by its document number or by the vendor's invoice number, in a currency the credit memo can be applied to.
    /// </summary>
    internal procedure TryResolveOpenInvoice(PayToVendorNo: Code[20]; CurrencyCode: Code[10]; Reference: Text; var PostedInvoiceNo: Code[20]; var FailureReason: Text): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        SeenEntryNos: List of [Integer];
        CurrencyMismatchInvoiceNo: Code[20];
        VendorNotSetErr: Label 'A vendor must be assigned before the invoice to apply to can be found.';
        InvoiceNotFoundErr: Label 'No open purchase invoice %1 was found for vendor %2.', Comment = '%1 = invoice number, %2 = vendor number';
        InvoiceAmbiguousErr: Label 'More than one open purchase invoice of vendor %2 matches %1. Enter a number that identifies only one of them, or clear the field and apply the credit memo manually after posting.', Comment = '%1 = invoice number, %2 = vendor number';
        CurrencyNotApplicableErr: Label 'Purchase invoice %1 is in a currency that this credit memo cannot be applied to.', Comment = '%1 = posted invoice number';
    begin
        Clear(PostedInvoiceNo);
        Clear(FailureReason);
        Reference := DelChr(Reference, '<>', ' ');
        if Reference = '' then begin
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'NotStated');
            exit(false);
        end;
        if PayToVendorNo = '' then begin
            FailureReason := VendorNotSetErr;
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'VendorMissing');
            exit(false);
        end;

        if GeneralLedgerSetup.Get() and (CurrencyCode = GeneralLedgerSetup."LCY Code") then
            CurrencyCode := '';

        VendorLedgerEntry.SetLoadFields("Entry No.", "Document No.", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", PayToVendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange(Open, true);
        if StrLen(Reference) <= MaxStrLen(VendorLedgerEntry."Document No.") then begin
            VendorLedgerEntry.SetRange("Document No.", Reference);
            if not TryMatchOpenInvoice(VendorLedgerEntry, CurrencyCode, SeenEntryNos, PostedInvoiceNo, CurrencyMismatchInvoiceNo) then begin
                FailureReason := StrSubstNo(InvoiceAmbiguousErr, Reference, PayToVendorNo);
                EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'Ambiguous');
                exit(false);
            end;
            VendorLedgerEntry.SetRange("Document No.");
        end;
        if StrLen(Reference) <= MaxStrLen(VendorLedgerEntry."External Document No.") then begin
            VendorLedgerEntry.SetRange("External Document No.", Reference);
            if not TryMatchOpenInvoice(VendorLedgerEntry, CurrencyCode, SeenEntryNos, PostedInvoiceNo, CurrencyMismatchInvoiceNo) then begin
                FailureReason := StrSubstNo(InvoiceAmbiguousErr, Reference, PayToVendorNo);
                EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'Ambiguous');
                exit(false);
            end;
        end;

        if PostedInvoiceNo <> '' then begin
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'Resolved');
            exit(true);
        end;
        if CurrencyMismatchInvoiceNo <> '' then begin
            FailureReason := StrSubstNo(CurrencyNotApplicableErr, CurrencyMismatchInvoiceNo);
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'CurrencyMismatch');
        end else begin
            FailureReason := StrSubstNo(InvoiceNotFoundErr, Reference, PayToVendorNo);
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'NotFound');
        end;
        exit(false);
    end;

    internal procedure GetAppliesToResolutionTok(): Text
    begin
        exit('AppliesToResolution');
    end;

    // Reads the matching open invoices straight from the filtered iteration (no Get per entry).
    // Returns false when the references resolve to more than one distinct open invoice (ambiguous).
    local procedure TryMatchOpenInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; var SeenEntryNos: List of [Integer]; var PostedInvoiceNo: Code[20]; var CurrencyMismatchInvoiceNo: Code[20]): Boolean
    var
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
    begin
        if VendorLedgerEntry.FindSet() then
            repeat
                if not SeenEntryNos.Contains(VendorLedgerEntry."Entry No.") then begin
                    SeenEntryNos.Add(VendorLedgerEntry."Entry No.");
                    if GenJnlApply.CheckAgainstApplnCurrency(CurrencyCode, VendorLedgerEntry."Currency Code", Enum::"Gen. Journal Account Type"::Vendor, false) then begin
                        if PostedInvoiceNo <> '' then begin
                            Clear(PostedInvoiceNo);
                            exit(false);
                        end;
                        PostedInvoiceNo := VendorLedgerEntry."Document No.";
                    end else
                        CurrencyMismatchInvoiceNo := VendorLedgerEntry."Document No.";
                end;
            until VendorLedgerEntry.Next() = 0;
        exit(true);
    end;

    internal procedure GetPayToVendorNo(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetLoadFields("Pay-to Vendor No.");
        if Vendor.Get(VendorNo) then
            if Vendor."Pay-to Vendor No." <> '' then
                exit(Vendor."Pay-to Vendor No.");
        exit(VendorNo);
    end;

    /// <summary>
    /// Sets "Applies-to Doc. No." on the credit memo draft to the open posted invoice identified by "Vendor Invoice No." for the draft's vendor, or clears it.
    /// </summary>
    /// <returns>True when the invoice was found; otherwise false, with the reason in FailureReason (empty when the draft states no invoice).</returns>
    internal procedure ResolveInvoiceToApplyTo(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var FailureReason: Text): Boolean
    var
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        PostedInvoiceNo: Code[20];
        SeveralInvoicesReferencedErr: Label 'The credit note refers to several invoices (%1).', Comment = '%1 = list of invoice numbers';
    begin
        Clear(FailureReason);
        EDocumentPurchaseHeader."Applies-to Doc. No." := '';
        if EDocumentPurchaseHeader."Vendor Invoice No." = '' then begin
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'NotStated');
            exit(false);
        end;

        // The ledger decides, not the punctuation: a number that identifies one open invoice is applied
        // to even when it contains characters that also separate several references.
        if TryResolveOpenInvoice(
            GetPayToVendorNo(EDocumentPurchaseHeader."[BC] Vendor No."), EDocumentPurchaseHeader."Currency Code",
            EDocumentPurchaseHeader."Vendor Invoice No.", PostedInvoiceNo, FailureReason)
        then begin
            EDocumentPurchaseHeader."Applies-to Doc. No." := PostedInvoiceNo;
            exit(true);
        end;

        // It did not identify one invoice. A draft that lists several explains that better than "not found",
        // but only once a vendor is known - otherwise the vendor message is the one the user needs.
        if (EDocumentPurchaseHeader."[BC] Vendor No." <> '') and
           EDocPurchaseDraftUtility.ReferencesSeveralInvoices(EDocumentPurchaseHeader."Vendor Invoice No.")
        then begin
            FailureReason := StrSubstNo(SeveralInvoicesReferencedErr, EDocumentPurchaseHeader."Vendor Invoice No.");
            EDocImpSessionTelemetry.SetText(GetAppliesToResolutionTok(), 'SeveralReferenced');
        end;
        exit(false);
    end;

    /// <summary>
    /// Describes what happens when a credit memo is posted without Applies-to Doc. No.
    /// </summary>
    internal procedure GetNotAppliedOutcome(VendorNo: Code[20]): Text
    var
        Vendor: Record Vendor;
        NotAppliedToOldestMsg: Label 'The credit memo is not applied to an invoice, even though the vendor''s application method is Apply to Oldest; apply it after posting.';
        NotAppliedMsg: Label 'The credit memo is not applied to an invoice; apply it after posting.';
    begin
        Vendor.SetLoadFields("Application Method");
        if Vendor.Get(GetPayToVendorNo(VendorNo)) then
            if Vendor."Application Method" = Vendor."Application Method"::"Apply to Oldest" then
                exit(NotAppliedToOldestMsg);
        exit(NotAppliedMsg);
    end;

    /// <summary>
    /// Keeps a credit memo that is not applied to an invoice from being applied to unrelated invoices when it is posted.
    /// Posting applies a credit memo with neither Applies-to Doc. No. nor Applies-to ID to the oldest open invoices when the vendor's
    /// application method is Apply to Oldest. Setting Applies-to ID to the credit memo's own number, as Apply Entries does, limits
    /// posting to the entries marked with that ID, and none are.
    /// </summary>
    internal procedure PreventApplyToOldestOnPosting(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        if (PurchaseHeader."Applies-to Doc. No." <> '') or (PurchaseHeader."Applies-to ID" <> '') or (PurchaseHeader."Bal. Account No." <> '') then
            exit;
        Vendor.SetLoadFields("Application Method");
        if not Vendor.Get(PurchaseHeader."Pay-to Vendor No.") then
            exit;
        if Vendor."Application Method" = Vendor."Application Method"::"Apply to Oldest" then
            ValidateFieldWithContext(PurchaseHeader, PurchaseHeader.FieldNo("Applies-to ID"), PurchaseHeader."No.");
    end;

    local procedure ComputeTotalLineAmount(EDocEntryNo: Integer; AmountRoundingPrecision: Decimal): Decimal
    var
        EDocPurchLine: Record "E-Document Purchase Line";
        TotalLineAmount: Decimal;
    begin
        EDocPurchLine.SetRange("E-Document Entry No.", EDocEntryNo);
        if EDocPurchLine.FindSet() then
            repeat
                TotalLineAmount += Round(
                    EDocPurchLine.Quantity * EDocPurchLine."Unit Price" - EDocPurchLine."Total Discount",
                    AmountRoundingPrecision);
            until EDocPurchLine.Next() = 0;
        exit(TotalLineAmount);
    end;
}
