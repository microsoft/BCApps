// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 324 "Payment Discount Policy" implements "Payment Discount Policy"
{
    procedure CheckVATPaymentDiscountAdjustment(GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.TestField("Adjust for Payment Disc.", true);
    end;

    procedure CheckPaymentDiscountPosting(GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.TestField("Adjust for Payment Disc.", true);
    end;

    procedure ShouldAdjustVATForPaymentDiscount(GLSetup: Record "General Ledger Setup"): Boolean
    begin
        exit(not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc.");
    end;

    procedure ShouldCalculatePaymentDiscountOnLines(GLSetup: Record "General Ledger Setup"): Boolean
    begin
        exit(false);
    end;

    procedure CalculateLineAmountForVAT(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; PaymentDiscountAmount: Decimal): Decimal
    begin
        exit(LineAmount);
    end;

    procedure CalculateInvoiceDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; DiscountPercent: Decimal; RoundingPrecision: Decimal; var Remainder: Decimal) DiscountAmount: Decimal
    begin
        Remainder += LineAmount * DiscountPercent / 100;
        DiscountAmount := Round(Remainder, RoundingPrecision);
        Remainder -= DiscountAmount;
    end;

#pragma warning disable AA0150
    procedure CalculateLinePaymentDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; InvoiceDiscountAmount: Decimal; DiscountPercent: Decimal; var Remainder: Decimal): Decimal
#pragma warning restore AA0150
    begin
        // W1 calculates payment discounts on ledger entries, not on invoice lines.
        exit(0);
    end;

    procedure CalculatePaymentDiscountBase(GLSetup: Record "General Ledger Setup"; GenJournalLine: Record "Gen. Journal Line"; VATAmountLCY: Decimal): Decimal
    begin
        if not GLSetup."Pmt. Disc. Excl. VAT" then
            exit(GenJournalLine.Amount);

        if GenJournalLine."Sales/Purch. (LCY)" = 0 then
            exit((GenJournalLine."Amount (LCY)" + VATAmountLCY) * GenJournalLine.Amount / GenJournalLine."Amount (LCY)");

        exit(GenJournalLine."Sales/Purch. (LCY)" * GenJournalLine.Amount / GenJournalLine."Amount (LCY)");
    end;
}
