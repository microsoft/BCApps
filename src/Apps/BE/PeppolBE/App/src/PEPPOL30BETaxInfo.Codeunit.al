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
/// Belgian PEPPOL tax info provider. Delegates every method to the default PEPPOL30 implementation,
/// except that it excludes the payment discount from the tax totals so that the PEPPOL document totals
/// (TaxableAmount, TaxExclusiveAmount, TaxInclusiveAmount, PayableAmount) match the invoice printout.
/// </summary>
codeunit 37315 "PEPPOL30 BE Tax Info" implements "PEPPOL Tax Info Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30: Codeunit "PEPPOL30";

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
        // In Belgium the payment discount must not reduce the PEPPOL document totals. Zeroing the payment
        // discount on the by-value sales line before accumulation keeps TaxableAmount, TaxExclusiveAmount,
        // TaxInclusiveAmount and PayableAmount aligned with the invoice printout, and the payment discount
        // AllowanceCharge is skipped by its existing zero-amount guard.
        SalesLine."Pmt. Discount Amount" := 0;
        PEPPOL30.GetTaxTotals(SalesLine, VATAmtLine);
    end;

    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group")
    begin
        PEPPOL30.GetTaxCategories(SalesLine, VATProductPostingGroupCategory);
    end;

    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text)
    begin
        PEPPOL30.GetTaxExemptionReason(VATProductPostingGroupCategory, TaxExemptionReasonTxt, TaxCategoryID);
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
