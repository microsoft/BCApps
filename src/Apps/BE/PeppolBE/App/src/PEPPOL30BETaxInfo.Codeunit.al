// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Peppol;
using Microsoft.Sales.Document;

/// <summary>
/// Belgian PEPPOL tax info provider. Delegates every method to the default PEPPOL30 implementation and,
/// via FinalizeTaxTotals, appends a compensating Exempt (category E) VAT breakdown line for the
/// conditional payment discount (escompte). This keeps VAT on the discounted base (as required in
/// Belgium) while the amount payable stays whole.
/// </summary>
codeunit 37315 "PEPPOL30 BE Tax Info" implements "PEPPOL Tax Info Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30: Codeunit "PEPPOL30";
        Escompte: Codeunit "PEPPOL30 BE Escompte";

    procedure GetAllowanceChargeInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOL30.GetAllowanceChargeInfo(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
    begin
        PEPPOL30.GetAllowanceChargeInfoBIS(VATAmtLine, SalesHeader, ChargeIndicator, AllowanceChargeReasonCode, AllowanceChargeListID, AllowanceChargeReason, Amount, AllowanceChargeCurrencyID, TaxCategoryID, TaxCategorySchemeID, Percent, AllowanceChargeTaxSchemeID);
    end;

    procedure GetTaxExchangeRateInfo(SalesHeader: Record "Sales Header"; var SourceCurrencyCode: Text; var SourceCurrencyCodeListID: Text; var TargetCurrencyCode: Text; var TargetCurrencyCodeListID: Text; var CalculationRate: Text; var MathematicOperatorCode: Text; var Date: Text)
    begin
        PEPPOL30.GetTaxExchangeRateInfo(SalesHeader, SourceCurrencyCode, SourceCurrencyCodeListID, TargetCurrencyCode, TargetCurrencyCodeListID, CalculationRate, MathematicOperatorCode, Date);
    end;

    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOL30.GetTaxTotalInfo(SalesHeader, VATAmtLine, TaxAmount, TaxTotalCurrencyID);
    end;

    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text)
    begin
        PEPPOL30.GetTaxSubtotalInfo(VATAmtLine, SalesHeader, TaxableAmount, TaxAmountCurrencyID, SubtotalTaxAmount, TaxSubtotalCurrencyID, TransactionCurrencyTaxAmount, TransCurrTaxAmtCurrencyID, TaxTotalTaxCategoryID, schemeID, TaxCategoryPercent, TaxTotalTaxSchemeID);
    end;

    procedure GetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text)
    begin
        PEPPOL30.GetTaxTotalInfoLCY(SalesHeader, TaxAmount, TaxCurrencyID, TaxTotalCurrencyID);
    end;

    procedure GetTaxTotals(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line")
    begin
        PEPPOL30.GetTaxTotals(SalesLine, VATAmtLine);
    end;

    procedure FinalizeTaxTotals(var VATAmtLine: Record "VAT Amount Line")
    var
        TotalPmtDiscount: Decimal;
    begin
        VATAmtLine.Reset();
        VATAmtLine.CalcSums("Pmt. Discount Amount");
        TotalPmtDiscount := VATAmtLine."Pmt. Discount Amount";
        if TotalPmtDiscount = 0 then
            exit;

        VATAmtLine.Init();
        VATAmtLine."VAT Identifier" := Escompte.GetCompensationVATIdentifier();
        VATAmtLine."VAT Calculation Type" := VATAmtLine."VAT Calculation Type"::"Normal VAT";
        VATAmtLine.Positive := true;
        VATAmtLine."Tax Category" := Escompte.GetExemptTaxCategory();
        VATAmtLine."VAT %" := 0;
        VATAmtLine."VAT Base" := TotalPmtDiscount;
        VATAmtLine."Amount Including VAT" := TotalPmtDiscount;
        VATAmtLine."VAT Amount" := 0;
        VATAmtLine."Pmt. Discount Amount" := 0;
        VATAmtLine."Invoice Discount Amount" := 0;
        VATAmtLine.Insert();
    end;

    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
    begin
        PEPPOL30.GetTaxCategories(SalesLine, VATProductPostingGroupCategory);
    end;

    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        PEPPOL30.GetTaxExemptionReason(VATProductPostingGroupCategory, TaxExemptionReasonTxt, TaxCategoryID);
        if (TaxExemptionReasonTxt = '') and (TaxCategoryID = Escompte.GetExemptTaxCategory()) then
            TaxExemptionReasonTxt := Escompte.GetCompensationExemptionReason();
    end;

    procedure IsZeroVatCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(PEPPOL30.IsZeroVatCategory(TaxCategory));
    end;

    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(PEPPOL30.IsStandardVATCategory(TaxCategory));
    end;

    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean
    begin
        exit(PEPPOL30.IsOutsideScopeVATCategory(TaxCategory));
    end;
}
