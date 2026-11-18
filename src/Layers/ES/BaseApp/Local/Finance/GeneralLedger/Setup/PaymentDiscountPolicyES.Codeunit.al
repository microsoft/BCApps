// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 10800 "Payment Discount Policy ES" implements "Payment Discount Policy"
{
    procedure CheckVATPaymentDiscountAdjustment(GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Adjust for Payment Disc.");
    end;

    procedure CheckPaymentDiscountPosting(GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
    end;

    procedure ShouldAdjustVATForPaymentDiscount(GLSetup: Record "General Ledger Setup"): Boolean
    begin
        // Preserve the ledger-posting checks independently of the ES option-based setup validation.
        exit(not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc.");
    end;

    procedure ShouldCalculatePaymentDiscountOnLines(GLSetup: Record "General Ledger Setup"): Boolean
    begin
        exit(GLSetup."Payment Discount Type" = GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
    end;

    procedure CalculateLineAmountForVAT(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; PaymentDiscountAmount: Decimal): Decimal
    begin
        exit(LineAmount - PaymentDiscountAmount);
    end;

    procedure CalculateInvoiceDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; DiscountPercent: Decimal; RoundingPrecision: Decimal; var Remainder: Decimal): Decimal
    var
        PaymentDiscountPolicy: Codeunit "Payment Discount Policy";
        DiscountBase: Decimal;
    begin
        case GLSetup."Discount Calculation" of
            GLSetup."Discount Calculation"::" ",
            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.",
            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.":
                DiscountBase := LineAmount;
            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. + Payment Disc.",
            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. * Payment Disc.":
                DiscountBase := LineAmount + LineDiscountAmount;
            else
                GLSetup.FieldError("Discount Calculation");
        end;

        exit(PaymentDiscountPolicy.CalculateInvoiceDiscount(GLSetup, DiscountBase, 0, DiscountPercent, RoundingPrecision, Remainder));
    end;

    procedure CalculateLinePaymentDiscount(GLSetup: Record "General Ledger Setup"; LineAmount: Decimal; LineDiscountAmount: Decimal; InvoiceDiscountAmount: Decimal; DiscountPercent: Decimal; var Remainder: Decimal) DiscountAmount: Decimal
    var
        DiscountBase: Decimal;
    begin
        if not ShouldCalculatePaymentDiscountOnLines(GLSetup) then
            exit(0);

        GLSetup.TestField("Discount Calculation");
        if LineAmount = 0 then
            exit(0);

        case GLSetup."Discount Calculation" of
            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. + Payment Disc.",
            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.":
                DiscountBase := LineAmount + LineDiscountAmount;
            GLSetup."Discount Calculation"::"Line Disc. + Inv. Disc. * Payment Disc.",
            GLSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.":
                DiscountBase := LineAmount - InvoiceDiscountAmount;
            else
                GLSetup.FieldError("Discount Calculation");
        end;

        Remainder += DiscountBase * DiscountPercent / 100;
        DiscountAmount := Round(Remainder, 0.01);
        Remainder -= DiscountAmount;
    end;

    procedure CalculatePaymentDiscountBase(GLSetup: Record "General Ledger Setup"; GenJournalLine: Record "Gen. Journal Line"; VATAmountLCY: Decimal): Decimal
    begin
        if GLSetup."Pmt. Disc. Excl. VAT" then
            exit(GenJournalLine."Sales/Purch. (LCY)" * GenJournalLine.Amount / GenJournalLine."Amount (LCY)");

        exit(GenJournalLine.Amount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterGetPaymentDiscountPolicy', '', false, false)]
    local procedure OnAfterGetPaymentDiscountPolicy(var PaymentDiscountPolicy: Interface "Payment Discount Policy")
    var
        PaymentDiscountPolicyES: Codeunit "Payment Discount Policy ES";
    begin
        PaymentDiscountPolicy := PaymentDiscountPolicyES;
    end;
}
