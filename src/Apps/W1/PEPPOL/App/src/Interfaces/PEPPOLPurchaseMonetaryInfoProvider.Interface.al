// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Monetary Info Provider"
{
    /// <summary>
    /// Gets legal monetary information from the purchase header including line extension amounts, tax amounts, allowances, charges, and payable amounts.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="TempPurchaseLine">The temporary purchase line record containing line details.</param>
    /// <param name="VATAmtLine">The VAT amount line record containing tax totals.</param>
    /// <param name="LineExtensionAmount">Returns the total line extension amount.</param>
    /// <param name="LegalMonetaryTotalCurrencyID">Returns the legal monetary total currency ID.</param>
    /// <param name="TaxExclusiveAmount">Returns the tax exclusive amount.</param>
    /// <param name="TaxExclusiveAmountCurrencyID">Returns the tax exclusive amount currency ID.</param>
    /// <param name="TaxInclusiveAmount">Returns the tax inclusive amount.</param>
    /// <param name="TaxInclusiveAmountCurrencyID">Returns the tax inclusive amount currency ID.</param>
    /// <param name="AllowanceTotalAmount">Returns the total allowance amount.</param>
    /// <param name="AllowanceTotalAmountCurrencyID">Returns the allowance total amount currency ID.</param>
    /// <param name="ChargeTotalAmount">Returns the total charge amount.</param>
    /// <param name="ChargeTotalAmountCurrencyID">Returns the charge total amount currency ID.</param>
    /// <param name="PrepaidAmount">Returns the prepaid amount.</param>
    /// <param name="PrepaidCurrencyID">Returns the prepaid currency ID.</param>
    /// <param name="PayableRoundingAmount">Returns the payable rounding amount.</param>
    /// <param name="PayableRndingAmountCurrencyID">Returns the payable rounding amount currency ID.</param>
    /// <param name="PayableAmount">Returns the final payable amount.</param>
    /// <param name="PayableAmountCurrencyID">Returns the payable amount currency ID.</param>
    procedure GetLegalMonetaryInfo(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)

    /// <summary>
    /// Gets the invoice rounding line from purchase line data.
    /// </summary>
    /// <param name="TempPurchaseLine">Returns the temporary purchase line containing rounding information.</param>
    /// <param name="PurchaseLine">The source purchase line record.</param>
    procedure GetInvoiceRoundingLine(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
}
