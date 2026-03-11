// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Document;

/// <summary>
/// Interface for providing tax-related information for PEPPOL document generation.
/// Handles VAT calculations, tax categories, allowances/charges, exchange rates,
/// and tax exemption reasons according to PEPPOL 3.0 standards.
/// </summary>
interface "PEPPOL Tax Info Provider"
{
    /// <summary>
    /// Gets allowance or charge information from VAT amount line and sales header for PEPPOL document generation.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance/charge details.</param>
    /// <param name="SalesHeader">The sales header record providing document context.</param>
    /// <param name="ChargeIndicator">Returns whether this is a charge (true) or allowance (false) indicator.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance/charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance/charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance/charge reason description.</param>
    /// <param name="Amount">Returns the allowance/charge amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance/charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID for the allowance/charge.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the tax percentage applied to the allowance/charge.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance/charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text);

    /// <summary>
    /// Gets allowance or charge information for BIS (Business Interoperability Specification) format.
    /// Provides allowance/charge details according to BIS billing specifications.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance/charge details.</param>
    /// <param name="SalesHeader">The sales header record providing document context.</param>
    /// <param name="ChargeIndicator">Returns whether this is a charge (true) or allowance (false) indicator.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance/charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance/charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance/charge reason description.</param>
    /// <param name="Amount">Returns the allowance/charge amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance/charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID for the allowance/charge.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the tax percentage applied to the allowance/charge.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance/charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfoBIS(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text);

    /// <summary>
    /// Gets tax exchange rate information when dealing with foreign currencies in tax calculations.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing currency and exchange rate information.</param>
    /// <param name="SourceCurrencyCode">Returns the source currency code.</param>
    /// <param name="SourceCurrencyCodeListID">Returns the source currency code list ID.</param>
    /// <param name="TargetCurrencyCode">Returns the target currency code.</param>
    /// <param name="TargetCurrencyCodeListID">Returns the target currency code list ID.</param>
    /// <param name="CalculationRate">Returns the exchange rate used for tax calculations.</param>
    /// <param name="MathematicOperatorCode">Returns the mathematical operator code for the exchange rate calculation.</param>
    /// <param name="Date">Returns the date of the exchange rate.</param>
    procedure GetTaxExchangeRateInfo(SalesHeader: Record "Sales Header"; var SourceCurrencyCode: Text; var SourceCurrencyCodeListID: Text; var TargetCurrencyCode: Text; var TargetCurrencyCodeListID: Text; var CalculationRate: Text; var MathematicOperatorCode: Text; var Date: Text);

    /// <summary>
    /// Gets the total tax amount information from the sales header and VAT amount lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing tax information.</param>
    /// <param name="VATAmtLine">The VAT amount line record containing tax totals.</param>
    /// <param name="TaxAmount">Returns the total tax amount.</param>
    /// <param name="TaxTotalCurrencyID">Returns the tax total currency ID.</param>
    procedure GetTaxTotalInfo(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var TaxAmount: Text; var TaxTotalCurrencyID: Text);

    /// <summary>
    /// Gets detailed tax subtotal information for a specific VAT amount line including taxable amounts, tax amounts, and tax category details.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing tax subtotal details.</param>
    /// <param name="SalesHeader">The sales header record providing document context.</param>
    /// <param name="TaxableAmount">Returns the taxable amount (base amount for tax calculation).</param>
    /// <param name="TaxAmountCurrencyID">Returns the tax amount currency ID.</param>
    /// <param name="SubtotalTaxAmount">Returns the subtotal tax amount.</param>
    /// <param name="TaxSubtotalCurrencyID">Returns the tax subtotal currency ID.</param>
    /// <param name="TransactionCurrencyTaxAmount">Returns the transaction currency tax amount.</param>
    /// <param name="TransCurrTaxAmtCurrencyID">Returns the transaction currency tax amount currency ID.</param>
    /// <param name="TaxTotalTaxCategoryID">Returns the tax total tax category ID.</param>
    /// <param name="schemeID">Returns the scheme ID for the tax category.</param>
    /// <param name="TaxCategoryPercent">Returns the tax category percentage.</param>
    /// <param name="TaxTotalTaxSchemeID">Returns the tax total tax scheme ID.</param>
    procedure GetTaxSubtotalInfo(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var TaxableAmount: Text; var TaxAmountCurrencyID: Text; var SubtotalTaxAmount: Text; var TaxSubtotalCurrencyID: Text; var TransactionCurrencyTaxAmount: Text; var TransCurrTaxAmtCurrencyID: Text; var TaxTotalTaxCategoryID: Text; var schemeID: Text; var TaxCategoryPercent: Text; var TaxTotalTaxSchemeID: Text);

    /// <summary>
    /// Gets tax total information in local currency (LCY) from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record containing tax information.</param>
    /// <param name="TaxAmount">Returns the tax amount in local currency.</param>
    /// <param name="TaxCurrencyID">Returns the tax currency ID.</param>
    /// <param name="TaxTotalCurrencyID">Returns the tax total currency ID.</param>
    procedure GetTaxTotalInfoLCY(SalesHeader: Record "Sales Header"; var TaxAmount: Text; var TaxCurrencyID: Text; var TaxTotalCurrencyID: Text);

    /// <summary>
    /// Calculates and retrieves totals from sales line information, populating VAT amount lines.
    /// </summary>
    /// <param name="SalesLine">The sales line record to calculate totals from.</param>
    /// <param name="VATAmtLine">Returns the calculated VAT amount line totals.</param>
    procedure GetTaxTotals(SalesLine: Record "Sales Line"; var VATAmtLine: Record "VAT Amount Line");

    /// <summary>
    /// Gets tax categories from the sales line and populates VAT product posting group category information.
    /// </summary>
    /// <param name="SalesLine">The sales line record containing tax category information.</param>
    /// <param name="VATProductPostingGroupCategory">Returns the VAT product posting group category information.</param>
    procedure GetTaxCategories(SalesLine: Record "Sales Line"; var VATProductPostingGroupCategory: Record "VAT Product Posting Group");

    /// <summary>
    /// Gets the tax exemption reason text based on VAT product posting group category and tax category ID.
    /// </summary>
    /// <param name="VATProductPostingGroupCategory">The VAT product posting group category record.</param>
    /// <param name="TaxExemptionReasonTxt">Returns the tax exemption reason text.</param>
    /// <param name="TaxCategoryID">The tax category ID to get exemption reason for.</param>
    procedure GetTaxExemptionReason(var VATProductPostingGroupCategory: Record "VAT Product Posting Group"; var TaxExemptionReasonTxt: Text; TaxCategoryID: Text);

    /// <summary>
    /// Checks if the given tax category represents a zero VAT rate category.
    /// Includes categories: Z (Zero rated), E (Exempt), AE (VAT reverse charge), K (EEA intra-community), G (Free export), O (Outside VAT scope).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category represents zero VAT, false otherwise.</returns>
    procedure IsZeroVatCategory(TaxCategory: Code[10]): Boolean;

    /// <summary>
    /// Checks if the given tax category represents a standard VAT category (S - Standard rate).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category is standard VAT, false otherwise.</returns>
    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean;

    /// <summary>
    /// Checks if the given tax category represents outside the scope of VAT (O - Outside the scope of VAT).
    /// </summary>
    /// <param name="TaxCategory">The tax category code to check.</param>
    /// <returns>True if the tax category is outside VAT scope, false otherwise.</returns>
    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean;
}
