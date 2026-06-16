// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;

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
