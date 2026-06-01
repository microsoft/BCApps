// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Document;

interface "PEPPOL Payment Info Provider"
{
    /// <summary>
    /// Gets payment means information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="PaymentMeansCode">Return value: Payment means code.</param>
    /// <param name="PaymentMeansListID">Return value: Payment means list ID.</param>
    /// <param name="PaymentDueDate">Return value: Payment due date.</param>
    /// <param name="PaymentChannelCode">Return value: Payment channel code.</param>
    /// <param name="PaymentID">Return value: Payment ID.</param>
    /// <param name="PrimaryAccountNumberID">Return value: Primary account number ID.</param>
    /// <param name="NetworkID">Return value: Network ID.</param>
    procedure GetPaymentMeansInfo(SalesHeader: Record "Sales Header"; var PaymentMeansCode: Text; var PaymentMeansListID: Text; var PaymentDueDate: Text; var PaymentChannelCode: Text; var PaymentID: Text; var PrimaryAccountNumberID: Text; var NetworkID: Text)

    /// <summary>
    /// Gets payment means payee financial account information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="PaymentMeansSchemeID">Return value: Payment means scheme ID.</param>
    /// <param name="FinancialInstitutionBranchID">Return value: Financial institution branch ID.</param>
    /// <param name="FinancialInstitutionID">Return value: Financial institution ID.</param>
    /// <param name="FinancialInstitutionSchemeID">Return value: Financial institution scheme ID.</param>
    /// <param name="FinancialInstitutionName">Return value: Financial institution name.</param>
    procedure GetPaymentMeansPayeeFinancialAcc(var PayeeFinancialAccountID: Text; var PaymentMeansSchemeID: Text; var FinancialInstitutionBranchID: Text; var FinancialInstitutionID: Text; var FinancialInstitutionSchemeID: Text; var FinancialInstitutionName: Text)

    /// <summary>
    /// Gets payment means payee financial account information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="PayeeFinancialAccountID">Return value: Payee financial account ID.</param>
    /// <param name="FinancialInstitutionBranchID">Return value: Financial institution branch ID.</param>
    procedure GetPaymentMeansPayeeFinancialAccBIS(SalesHeader: Record "Sales Header"; var PayeeFinancialAccountID: Text; var FinancialInstitutionBranchID: Text)

    /// <summary>
    /// Gets payment means financial institution address information.
    /// </summary>
    /// <param name="FinancialInstitutionStreetName">Return value: Financial institution street name.</param>
    /// <param name="AdditionalStreetName">Return value: Additional street name.</param>
    /// <param name="FinancialInstitutionCityName">Return value: Financial institution city name.</param>
    /// <param name="FinancialInstitutionPostalZone">Return value: Financial institution postal zone.</param>
    /// <param name="FinancialInstCountrySubentity">Return value: Financial institution country subentity.</param>
    /// <param name="FinancialInstCountryIdCode">Return value: Financial institution country ID code.</param>
    /// <param name="FinancialInstCountryListID">Return value: Financial institution country list ID.</param>
    procedure GetPaymentMeansFinancialInstitutionAddr(var FinancialInstitutionStreetName: Text; var AdditionalStreetName: Text; var FinancialInstitutionCityName: Text; var FinancialInstitutionPostalZone: Text; var FinancialInstCountrySubentity: Text; var FinancialInstCountryIdCode: Text; var FinancialInstCountryListID: Text)

    /// <summary>
    /// Gets payment terms information for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="PaymentTermsNote">Return value: Payment terms note.</param>
    procedure GetPaymentTermsInfo(SalesHeader: Record "Sales Header"; var PaymentTermsNote: Text)

    /// <summary>
    /// Gets allowance charge information for payment discounts from VAT amount line and sales header.
    /// </summary>
    /// <param name="VATAmtLine">The VAT amount line record containing allowance charge information.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ChargeIndicator">Returns the charge indicator.</param>
    /// <param name="AllowanceChargeReasonCode">Returns the allowance charge reason code.</param>
    /// <param name="AllowanceChargeListID">Returns the allowance charge list ID.</param>
    /// <param name="AllowanceChargeReason">Returns the allowance charge reason.</param>
    /// <param name="Amount">Returns the amount.</param>
    /// <param name="AllowanceChargeCurrencyID">Returns the allowance charge currency ID.</param>
    /// <param name="TaxCategoryID">Returns the tax category ID.</param>
    /// <param name="TaxCategorySchemeID">Returns the tax category scheme ID.</param>
    /// <param name="Percent">Returns the percent.</param>
    /// <param name="AllowanceChargeTaxSchemeID">Returns the allowance charge tax scheme ID.</param>
    procedure GetAllowanceChargeInfoPaymentDiscount(VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; var ChargeIndicator: Text; var AllowanceChargeReasonCode: Text; var AllowanceChargeListID: Text; var AllowanceChargeReason: Text; var Amount: Text; var AllowanceChargeCurrencyID: Text; var TaxCategoryID: Text; var TaxCategorySchemeID: Text; var Percent: Text; var AllowanceChargeTaxSchemeID: Text)
}
