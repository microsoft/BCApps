// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Provides payment discount checks and calculations using the supplied setup and amounts.
/// Calculation remainders belong to the caller and must be retained between document lines.
/// </summary>
interface "Payment Discount Policy"
{
    procedure CheckVATPaymentDiscountAdjustment(GLSetup: Record "General Ledger Setup");

    procedure CheckPaymentDiscountPosting(GLSetup: Record "General Ledger Setup");

    procedure ShouldAdjustVATForPaymentDiscount(GLSetup: Record "General Ledger Setup"): Boolean;

    procedure ShouldCalculatePaymentDiscountOnLines(GLSetup: Record "General Ledger Setup"): Boolean;

    procedure CalculateLineAmountForVAT(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; PaymentDiscountAmount: Decimal): Decimal;

    procedure CalculateInvoiceDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; DiscountPercent: Decimal; RoundingPrecision: Decimal; var Remainder: Decimal): Decimal;

    procedure CalculateLinePaymentDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; InvoiceDiscountAmount: Decimal; DiscountPercent: Decimal; var Remainder: Decimal): Decimal;

    procedure CalculatePaymentDiscountBase(GLSetup: Record "General Ledger Setup"; GenJournalLine: Record "Gen. Journal Line"; VATAmountLCY: Decimal): Decimal;
}
