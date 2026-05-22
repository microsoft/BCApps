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
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;

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
        PurchaseLine."Unit of Measure Code" := CopyStr(EDocumentPurchaseLine."[BC] Unit of Measure", 1, MaxStrLen(PurchaseLine."Unit of Measure Code"));
        PurchaseLine."Variant Code" := EDocumentPurchaseLine."[BC] Variant Code";
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

        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo(Quantity), EDocumentPurchaseLine.Quantity);
        ValidateFieldWithContext(PurchaseLine, PurchaseLine.FieldNo("Direct Unit Cost"), EDocumentPurchaseLine."Unit Price");
        if EDocumentPurchaseLine."Total Discount" > 0 then
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
