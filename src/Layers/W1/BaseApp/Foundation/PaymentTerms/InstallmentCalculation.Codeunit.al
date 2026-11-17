// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

codeunit 8840 "Installment Calculation"
{
    var
        TemporaryRecordErr: Label 'Installment calculation requires a temporary plan line record.';
        PlanIdentityErr: Label 'All installment lines must belong to the same nonempty plan.';
        LineNoErr: Label 'Installment line %1 must have a positive line number.', Comment = '%1 = line number';
        PaymentPercentageErr: Label 'Payment % on installment line %1 must be greater than 0 and not exceed 100, with up to 5 decimal places.', Comment = '%1 = line number';
        DiscountPercentageErr: Label 'Discount % on installment line %1 must be between 0 and 100, with up to 5 decimal places.', Comment = '%1 = line number';
        TotalPercentageErr: Label 'Installment payment percentages must total 100.';
        RemainingLineErr: Label 'Remaining Amount must occur only on the final installment line, with a zero payment percentage and a positive remaining percentage. Check line %1.', Comment = '%1 = line number';
        MissingFormulaErr: Label '%1 must be specified on installment line %2.', Comment = '%1 = date formula field caption, %2 = line number';
        DateRequiredErr: Label 'Document Date and Posting Date must be specified to calculate installments.';
        AmountErr: Label 'The invoice amount must be positive, the LCY amount must not be negative, and both totals must respect their rounding precisions.';
        PrecisionErr: Label 'Document currency and LCY amount rounding precisions must be greater than zero.';
        DueDateErr: Label 'The due date on installment line %1 must not precede the document date or the preceding installment due date.', Comment = '%1 = line number';
        DiscountDateErr: Label 'The payment discount date on installment line %1 must be between the document date and the installment due date.', Comment = '%1 = line number';
        InstallmentAmountErr: Label 'Installment line %1 must have a positive amount and a nonnegative LCY amount after rounding.', Comment = '%1 = line number';
        UnsupportedAllocationErr: Label 'The allocation type on installment line %1 is not supported.', Comment = '%1 = line number';

    procedure CopyPaymentTerms(PaymentTermsCode: Code[10]; PlanID: Guid; var TempPlanLine: Record "Installment Plan Line" temporary): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermInstallment: Record "Payment Term Installment";
        TempRule: Record "Installment Plan Line" temporary;
    begin
        CheckTemporary(TempPlanLine);
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTermInstallment.SetRange("Payment Terms Code", PaymentTermsCode);
        if PaymentTermInstallment.FindSet() then
            repeat
                TempRule.Init();
                TempRule."Plan ID" := PlanID;
                TempRule.CopyFromPaymentTermInstallment(PaymentTermInstallment);
                TempRule.Insert();
            until PaymentTermInstallment.Next() = 0;

        ValidateRules(TempRule);
        ReplaceTemporaryLines(TempRule, TempPlanLine);
        exit(not TempPlanLine.IsEmpty());
    end;

    procedure ValidateRules(var TempPlanLine: Record "Installment Plan Line" temporary)
    var
        PlanID: Guid;
        TotalPercentage: Decimal;
        RemainingLineNo: Integer;
    begin
        CheckTemporary(TempPlanLine);
        TempPlanLine.Reset();
        if not TempPlanLine.FindSet() then
            exit;

        PlanID := TempPlanLine."Plan ID";
        repeat
            if IsNullGuid(PlanID) or (TempPlanLine."Plan ID" <> PlanID) then
                Error(PlanIdentityErr);
            if TempPlanLine."Line No." <= 0 then
                Error(LineNoErr, TempPlanLine."Line No.");
            if Format(TempPlanLine."Due Date Calculation") = '' then
                Error(MissingFormulaErr, TempPlanLine.FieldCaption("Due Date Calculation"), TempPlanLine."Line No.");
            if (TempPlanLine."Discount %" < 0) or (TempPlanLine."Discount %" > 100) or
               (TempPlanLine."Discount %" <> Round(TempPlanLine."Discount %", 0.00001))
            then
                Error(DiscountPercentageErr, TempPlanLine."Line No.");
            if (TempPlanLine."Discount %" <> 0) and (Format(TempPlanLine."Discount Date Calculation") = '') then
                Error(MissingFormulaErr, TempPlanLine.FieldCaption("Discount Date Calculation"), TempPlanLine."Line No.");

            case TempPlanLine."Allocation Type" of
                TempPlanLine."Allocation Type"::Percentage:
                    begin
                        if (TempPlanLine."Payment %" <= 0) or (TempPlanLine."Payment %" > 100) or
                           (TempPlanLine."Payment %" <> Round(TempPlanLine."Payment %", 0.00001))
                        then
                            Error(PaymentPercentageErr, TempPlanLine."Line No.");
                        TotalPercentage += TempPlanLine."Payment %";
                    end;
                TempPlanLine."Allocation Type"::"Remaining Amount":
                    begin
                        if (TempPlanLine."Payment %" <> 0) or (TotalPercentage >= 100) then
                            Error(RemainingLineErr, TempPlanLine."Line No.");
                        RemainingLineNo := TempPlanLine."Line No.";
                        if TempPlanLine.Next() <> 0 then
                            Error(RemainingLineErr, RemainingLineNo);
                        exit;
                    end;
                else
                    Error(UnsupportedAllocationErr, TempPlanLine."Line No.");
            end;
        until TempPlanLine.Next() = 0;

        if TotalPercentage <> 100 then
            Error(TotalPercentageErr);
    end;

    procedure CalculateDates(var TempPlanLine: Record "Installment Plan Line" temporary; DocumentDate: Date)
    var
        TempCalculatedLine: Record "Installment Plan Line" temporary;
        PreviousDueDate: Date;
    begin
        ValidateRules(TempPlanLine);
        if TempPlanLine.IsEmpty() then
            exit;
        if DocumentDate = 0D then
            Error(DateRequiredErr);
        TempPlanLine.FindSet();
        repeat
            TempCalculatedLine := TempPlanLine;
            CalculateLineDates(TempCalculatedLine, DocumentDate, PreviousDueDate);
            TempCalculatedLine.Insert();
        until TempPlanLine.Next() = 0;
        ReplaceTemporaryLines(TempCalculatedLine, TempPlanLine);
    end;

    // Calculation reads only the supplied snapshot and explicit accounting inputs.
    // Discount eligibility is limited to the M1 gross-amount policy.
    procedure Calculate(var TempPlanLine: Record "Installment Plan Line" temporary; DocumentDate: Date; PostingDate: Date; Amount: Decimal; AmountLCY: Decimal; AmountRoundingPrecision: Decimal; LCYAmountRoundingPrecision: Decimal; PaymentDiscountGracePeriod: DateFormula)
    var
        TempCalculatedLine: Record "Installment Plan Line" temporary;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        RemainingPercentage: Decimal;
        PaymentPercentage: Decimal;
        PreviousDueDate: Date;
        DiscountGraceDate: Date;
        InstallmentNo: Integer;
        LastLineNo: Integer;
    begin
        ValidateRules(TempPlanLine);
        if TempPlanLine.IsEmpty() then
            exit;
        if (DocumentDate = 0D) or (PostingDate = 0D) then
            Error(DateRequiredErr);
        if (AmountRoundingPrecision <= 0) or (LCYAmountRoundingPrecision <= 0) then
            Error(PrecisionErr);
        if (Amount <= 0) or (AmountLCY < 0) or
           (Amount <> Round(Amount, AmountRoundingPrecision)) or
           (AmountLCY <> Round(AmountLCY, LCYAmountRoundingPrecision))
        then
            Error(AmountErr);

        TempPlanLine.FindLast();
        LastLineNo := TempPlanLine."Line No.";
        RemainingAmount := Amount;
        RemainingAmountLCY := AmountLCY;
        RemainingPercentage := 100;
        TempPlanLine.FindSet();
        repeat
            TempCalculatedLine := TempPlanLine;
            InstallmentNo += 1;
            TempCalculatedLine."Installment No." := InstallmentNo;
            PaymentPercentage := TempPlanLine."Payment %";
            if TempPlanLine."Allocation Type" = TempPlanLine."Allocation Type"::"Remaining Amount" then
                PaymentPercentage := RemainingPercentage;
            TempCalculatedLine.Amount := Round(Amount * PaymentPercentage / 100, AmountRoundingPrecision);
            TempCalculatedLine."Amount (LCY)" := Round(AmountLCY * PaymentPercentage / 100, LCYAmountRoundingPrecision);
            TempCalculatedLine."Rounding Adjustment" := 0;
            TempCalculatedLine."Rounding Adjustment (LCY)" := 0;
            if TempPlanLine."Line No." = LastLineNo then begin
                TempCalculatedLine."Rounding Adjustment" := RemainingAmount - TempCalculatedLine.Amount;
                TempCalculatedLine."Rounding Adjustment (LCY)" := RemainingAmountLCY - TempCalculatedLine."Amount (LCY)";
                TempCalculatedLine.Amount := RemainingAmount;
                TempCalculatedLine."Amount (LCY)" := RemainingAmountLCY;
            end;
            if (TempCalculatedLine.Amount <= 0) or (TempCalculatedLine."Amount (LCY)" < 0) then
                Error(InstallmentAmountErr, TempCalculatedLine."Line No.");

            CalculateLineDates(TempCalculatedLine, DocumentDate, PreviousDueDate);
            TempCalculatedLine."Original Pmt. Disc. Possible" := 0;
            if TempCalculatedLine."Discount %" <> 0 then begin
                DiscountGraceDate := CalcDate(PaymentDiscountGracePeriod, TempCalculatedLine."Pmt. Discount Date");
                if (TempCalculatedLine."Amount (LCY)" <> 0) and (DiscountGraceDate >= PostingDate) then
                    TempCalculatedLine."Original Pmt. Disc. Possible" :=
                        Round(TempCalculatedLine.Amount * TempCalculatedLine."Discount %" / 100, AmountRoundingPrecision);
            end;
            TempCalculatedLine.Insert();
            RemainingAmount -= TempCalculatedLine.Amount;
            RemainingAmountLCY -= TempCalculatedLine."Amount (LCY)";
            RemainingPercentage -= PaymentPercentage;
        until TempPlanLine.Next() = 0;

        ReplaceTemporaryLines(TempCalculatedLine, TempPlanLine);
    end;

    local procedure CalculateLineDates(var TempPlanLine: Record "Installment Plan Line" temporary; DocumentDate: Date; var PreviousDueDate: Date)
    begin
        TempPlanLine."Due Date" := CalcDate(TempPlanLine."Due Date Calculation", DocumentDate);
        if (TempPlanLine."Due Date" < DocumentDate) or (TempPlanLine."Due Date" < PreviousDueDate) then
            Error(DueDateErr, TempPlanLine."Line No.");
        TempPlanLine."Pmt. Discount Date" := 0D;
        if TempPlanLine."Discount %" <> 0 then begin
            TempPlanLine."Pmt. Discount Date" := CalcDate(TempPlanLine."Discount Date Calculation", DocumentDate);
            if (TempPlanLine."Pmt. Discount Date" < DocumentDate) or
               (TempPlanLine."Pmt. Discount Date" > TempPlanLine."Due Date")
            then
                Error(DiscountDateErr, TempPlanLine."Line No.");
        end;
        PreviousDueDate := TempPlanLine."Due Date";
    end;

    local procedure CheckTemporary(var TempPlanLine: Record "Installment Plan Line" temporary)
    begin
        if not TempPlanLine.IsTemporary() then
            Error(TemporaryRecordErr);
    end;

    local procedure ReplaceTemporaryLines(var TempSource: Record "Installment Plan Line" temporary; var TempTarget: Record "Installment Plan Line" temporary)
    begin
        TempTarget.Reset();
        TempTarget.DeleteAll();
        TempSource.Reset();
        if TempSource.FindSet() then
            repeat
                TempTarget := TempSource;
                TempTarget.Insert();
            until TempSource.Next() = 0;
    end;
}
