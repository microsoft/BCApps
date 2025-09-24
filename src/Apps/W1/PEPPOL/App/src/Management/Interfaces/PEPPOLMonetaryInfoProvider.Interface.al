// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Document;

interface "PEPPOL Monetary Info Provider"
{    procedure GetLegalMonetaryInfo(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)

    /// <summary>
    /// Gets legal monetary document amounts for PEPPOL documents.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="VATAmtLine">The VAT amount line record.</param>
    /// <param name="LineExtensionAmount">Return value: Line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Return value: Legal monetary total currency ID.</param>
    /// <param name="TaxExclusiveAmount">Return value: Tax exclusive amount.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Return value: Tax exclusive amount currency ID.</param>
    /// <param name="TaxInclusiveAmount">Return value: Tax inclusive amount.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Return value: Tax inclusive amount currency ID.</param>
    /// <param name="AllowanceTotalAmount">Return value: Allowance total amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Return value: Allowance total amount currency ID.</param>
    /// <param name="ChargeTotalAmount">Return value: Charge total amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Return value: Charge total amount currency ID.</param>
    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)

    /// <summary>
    /// Gets invoice rounding line information for PEPPOL documents.
    /// </summary>
    /// <param name="TempSalesLine">Return value: Temporary sales line record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
}