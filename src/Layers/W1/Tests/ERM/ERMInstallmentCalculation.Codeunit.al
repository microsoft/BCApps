// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

codeunit 134491 "ERM Installment Calculation"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [Calculation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        InstallmentCalculation: Codeunit "Installment Calculation";

    [Test]
    procedure PercentagesUseOriginalTotalsAndDocumentDate()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Percentages use the original totals and due dates use the document date in rule order.
        // [GIVEN] Three percentage rules inserted out of sequence.
        AddPercentageRule(TempPlanLine, 30000, 40, '<90D>');
        AddPercentageRule(TempPlanLine, 10000, 30, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 30, '<60D>');

        // [WHEN] The schedule is calculated in document currency and LCY.
        Calculate(TempPlanLine, 10000, 12345, 0.01, 0.01);

        // [THEN] Each line receives its percentage of each original total and its due date in rule order.
        AssertLine(TempPlanLine, 10000, 3000, 3703.5, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 3000, 3703.5, DMY2Date(2, 3, 2026));
        AssertLine(TempPlanLine, 30000, 4000, 4938, DMY2Date(1, 4, 2026));
    end;

    [Test]
    procedure FinalLineReceivesIndependentCurrencyResiduals()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] The final installment absorbs document currency and LCY rounding residuals independently.
        // [GIVEN] Three nearly equal percentage rules.
        AddPercentageRule(TempPlanLine, 10000, 33.33333, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 33.33333, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 33.33334, '<90D>');

        // [WHEN] Totals with different rounding residuals are allocated.
        Calculate(TempPlanLine, 10000, 10.01, 0.01, 0.01);

        // [THEN] The final line balances each currency and records its independent rounding adjustment.
        AssertLine(TempPlanLine, 10000, 3333.33, 3.34, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 3333.33, 3.34, DMY2Date(2, 3, 2026));
        AssertLine(TempPlanLine, 30000, 3333.34, 3.33, DMY2Date(1, 4, 2026));
        TempPlanLine.FindLast();
        Assert.AreEqual(0.01, TempPlanLine."Rounding Adjustment", 'Document currency residual must be recorded.');
        Assert.AreEqual(-0.01, TempPlanLine."Rounding Adjustment (LCY)", 'LCY residual must be independent.');
    end;

    [Test]
    procedure RemainingAmountReceivesUnallocatedPercentage()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] A final remaining-amount rule receives the balance after percentage installments.
        // [GIVEN] Two 25 percent rules followed by a remaining-amount rule.
        AddPercentageRule(TempPlanLine, 10000, 25, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 25, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 0, '<90D>');
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        TempPlanLine.Modify();

        // [WHEN] The schedule is calculated.
        Calculate(TempPlanLine, 100, 123.45, 0.01, 0.01);

        // [THEN] The final line receives the unallocated balance in both currencies.
        AssertLine(TempPlanLine, 30000, 50, 61.73, DMY2Date(1, 4, 2026));
    end;

    [Test]
    procedure UsesWholeUnitDocumentCurrencyAndThreeDecimalLCYPrecisions()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Document currency uses whole-unit precision independently of three-decimal LCY precision.
        // [GIVEN] Two equal percentage rules.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');

        // [WHEN] Document currency uses whole units and LCY uses three decimal places.
        Calculate(TempPlanLine, 101, 1.001, 1, 0.001);
        // [THEN] Each currency is rounded to its own precision and the final line balances the total.
        AssertLine(TempPlanLine, 10000, 51, 0.501, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 50, 0.5, DMY2Date(2, 3, 2026));
    end;

    [Test]
    procedure UsesThreeDecimalDocumentCurrencyAndWholeUnitLCYPrecisions()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Document currency uses three-decimal precision independently of whole-unit LCY precision.
        // [GIVEN] Two equal percentage rules.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');

        // [WHEN] Document currency uses three decimal places and LCY uses whole units.
        Calculate(TempPlanLine, 1.001, 101, 0.001, 1);
        // [THEN] Each currency is rounded to its own precision and the final line balances the total.
        AssertLine(TempPlanLine, 10000, 0.501, 51, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 0.5, 50, DMY2Date(2, 3, 2026));
    end;

    [Test]
    procedure DiscountsUseEachLineAndPostingDateGracePeriod()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
        GracePeriod: DateFormula;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Each installment's own discount remains eligible through the last posting-date grace day.
        // [GIVEN] Two installments with different discount percentages and dates, and a five-day grace period.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        SetDiscount(TempPlanLine, 2, '<10D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        SetDiscount(TempPlanLine, 1, '<15D>');
        Evaluate(GracePeriod, '<5D>');

        // [WHEN] The posting date is the last grace day for the first installment.
        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(16, 1, 2026), 100, 100, 0.01, 0.01, GracePeriod);

        // [THEN] Discount dates use the document date and both line-specific discounts remain eligible.
        TempPlanLine.FindSet();
        Assert.AreEqual(DMY2Date(11, 1, 2026), TempPlanLine."Pmt. Discount Date", 'Discount date must use the document date.');
        Assert.AreEqual(1, TempPlanLine."Original Pmt. Disc. Possible", 'The last grace day must remain eligible.');
        TempPlanLine.Next();
        Assert.AreEqual(0.5, TempPlanLine."Original Pmt. Disc. Possible", 'Each line must use its own discount percentage.');
    end;

    [Test]
    procedure RecalculationAfterGracePeriodClearsOnlyExpiredDiscount()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
        GracePeriod: DateFormula;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Recalculation clears an expired discount without removing a later installment's eligibility.
        // [GIVEN] A schedule calculated while both line-specific discounts are still eligible.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        SetDiscount(TempPlanLine, 2, '<10D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        SetDiscount(TempPlanLine, 1, '<15D>');
        Evaluate(GracePeriod, '<5D>');
        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(16, 1, 2026), 100, 100, 0.01, 0.01, GracePeriod);

        // [WHEN] The schedule is recalculated one day after the first installment's grace period.
        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(17, 1, 2026), 100, 100, 0.01, 0.01, GracePeriod);

        // [THEN] The expired discount is cleared while the later discount remains eligible.
        TempPlanLine.FindSet();
        Assert.AreEqual(0, TempPlanLine."Original Pmt. Disc. Possible", 'Expired eligibility must be cleared on recalculation.');
        TempPlanLine.Next();
        Assert.AreEqual(0.5, TempPlanLine."Original Pmt. Disc. Possible", 'Later discount eligibility must be retained.');
    end;

    [Test]
    procedure ZeroLCYAllocationDoesNotCreateDiscountEligibility()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] An installment rounded to zero in LCY is not eligible for a payment discount.
        // [GIVEN] Two equal installments with the same payment discount.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        SetDiscount(TempPlanLine, 2, '<10D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        SetDiscount(TempPlanLine, 2, '<10D>');

        // [WHEN] The LCY total is too small to allocate a positive amount to both installments.
        Calculate(TempPlanLine, 100, 0.01, 0.01, 0.01);

        // [THEN] Only the installment with a nonzero LCY allocation has a possible discount.
        TempPlanLine.FindSet();
        Assert.AreEqual(0.01, TempPlanLine."Amount (LCY)", 'LCY must be allocated independently.');
        Assert.AreEqual(1, TempPlanLine."Original Pmt. Disc. Possible", 'A nonzero LCY allocation can be eligible.');
        TempPlanLine.Next();
        Assert.AreEqual(50, TempPlanLine.Amount, 'Document currency must retain its positive installment.');
        Assert.AreEqual(0, TempPlanLine."Amount (LCY)", 'The final LCY allocation may be zero.');
        Assert.AreEqual(0, TempPlanLine."Original Pmt. Disc. Possible", 'Match the standard zero-LCY discount behavior.');
    end;

    [Test]
    procedure RejectsIncompletePercentageTotal()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Percentage rules must allocate the full invoice total.
        // [GIVEN] Three percentage rules totaling 99.99 percent without a remaining-amount rule.
        AddPercentageRule(TempPlanLine, 10000, 33.33, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 33.33, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 33.33, '<90D>');

        // [WHEN] The schedule is calculated.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] Calculation is rejected because the percentages do not total 100.
        Assert.ExpectedError('percentages must total 100');
    end;

    [Test]
    procedure RejectsRemainingAmountBeforeFinalLine()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] A remaining-amount rule is allowed only on the final line.
        // [GIVEN] A remaining-amount rule followed by a percentage rule.
        AddPercentageRule(TempPlanLine, 10000, 0, '<30D>');
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        TempPlanLine.Modify();
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');

        // [WHEN] The schedule is calculated.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] Calculation identifies the misplaced remaining-amount rule.
        Assert.ExpectedError('Check line 10000');
    end;

    [Test]
    procedure RejectsMissingDueDateFormula()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Every installment rule requires a due-date formula.
        // [GIVEN] A percentage rule without a due-date formula.
        AddPercentageRule(TempPlanLine, 10000, 100, '');

        // [WHEN] The schedule is calculated.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] Calculation identifies the rule with the missing formula.
        Assert.ExpectedError('Due Date Calculation must be specified on installment line 10000');
    end;

    [Test]
    procedure RejectsDescendingDatesWithoutReplacingSnapshot()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Descending due dates are rejected without partially replacing the schedule.
        // [GIVEN] Two rules whose due dates decrease in line order.
        AddPercentageRule(TempPlanLine, 10000, 50, '<60D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<30D>');

        // [WHEN] The schedule is calculated.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] The invalid due date is reported and no partial amounts or installment numbers are assigned.
        Assert.ExpectedError('due date on installment line 20000');
        TempPlanLine.FindFirst();
        Assert.AreEqual(0, TempPlanLine.Amount, 'A failed calculation must not partially replace the snapshot.');
        Assert.AreEqual(0, TempPlanLine."Installment No.", 'A failed calculation must not assign partial sequence values.');
    end;

    [Test]
    procedure RejectsDiscountDateAfterDueDate()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] An installment's payment discount date cannot follow its due date.
        // [GIVEN] A rule with a discount date later than its due date.
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');
        SetDiscount(TempPlanLine, 2, '<31D>');

        // [WHEN] The schedule is calculated.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] Calculation identifies the invalid payment discount date.
        Assert.ExpectedError('payment discount date on installment line 10000');
    end;

    [Test]
    procedure RejectsZeroRoundedInstallment()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] An installment amount must remain positive after rounding.
        // [GIVEN] A one-percent installment followed by a 99-percent installment.
        AddPercentageRule(TempPlanLine, 10000, 1, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 99, '<60D>');

        // [WHEN] A total of 0.01 is allocated using a precision of 0.01.
        asserterror Calculate(TempPlanLine, 0.01, 0.01, 0.01, 0.01);

        // [THEN] Calculation rejects the first installment because its rounded amount is zero.
        Assert.ExpectedError('Installment line 10000 must have a positive amount');
    end;

    [Test]
    procedure RejectsInvalidRoundingPrecision()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Calculation requires positive rounding precisions.
        // [GIVEN] A rule allocating the entire invoice amount.
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');

        // [WHEN] The document currency rounding precision is zero.
        asserterror Calculate(TempPlanLine, 100, 100, 0, 0.01);

        // [THEN] Calculation reports that rounding precisions must be positive.
        Assert.ExpectedError('rounding precisions must be greater than zero');
    end;

    [Test]
    procedure RejectsMultiplePlansInOneCalculation()
    var
        TempPlanLine: Record "Installment Calculation Line" temporary;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] A calculation cannot combine rules belonging to different plans.
        // [GIVEN] Two percentage rules with different plan IDs.
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        TempPlanLine.Rename(CreateGuid(), TempPlanLine."Line No.");

        // [WHEN] The rules are calculated together.
        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] Calculation reports that all rules must belong to the same nonempty plan.
        Assert.ExpectedError('same nonempty plan');
    end;

    [Test]
    procedure OrdinaryTermsProduceNoSyntheticPlan()
    var
        PaymentTerms: Record "Payment Terms";
        TempPlanLine: Record "Installment Calculation Line" temporary;
        OriginalDueDateCalculation: DateFormula;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Loading ordinary payment terms clears a temporary schedule without creating an installment plan.
        // [GIVEN] Ordinary payment terms and an existing temporary installment rule.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        OriginalDueDateCalculation := PaymentTerms."Due Date Calculation";
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');

        // [WHEN] The ordinary payment terms are copied into the temporary schedule.
        Assert.IsFalse(
            InstallmentCalculation.CopyPaymentTerms(PaymentTerms.Code, CreateGuid(), TempPlanLine),
            'Ordinary terms must not create installment lines.');

        // [THEN] The schedule is empty and the original terms and their non-installment status remain unchanged.
        Assert.IsTrue(TempPlanLine.IsEmpty(), 'Explicitly loading ordinary terms must clear the old temporary schedule.');
        PaymentTerms.Get(PaymentTerms.Code);
        Assert.AreEqual(Format(OriginalDueDateCalculation), Format(PaymentTerms."Due Date Calculation"), 'Existing terms must remain unchanged.');
        PaymentTerms.CalcFields("Has Installments");
        Assert.IsFalse(PaymentTerms."Has Installments", 'Ordinary terms must not be marked as installment terms.');
    end;

    [Test]
    procedure SnapshotSurvivesSetupChangesAndDeletion()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermInstallment: Record "Payment Term Installment";
        TempPlanLine: Record "Installment Calculation Line" temporary;
        PlanID: Guid;
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] A temporary rule snapshot survives changes to and deletion of its source payment terms.
        // [GIVEN] A copied rule snapshot whose original setup is subsequently changed and deleted.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateSetupRule(PaymentTermInstallment, PaymentTerms.Code);
        PlanID := CreateGuid();
        Assert.IsTrue(
            InstallmentCalculation.CopyPaymentTerms(PaymentTerms.Code, PlanID, TempPlanLine),
            'Installment terms must produce a rule snapshot.');
        PaymentTerms.CalcFields("Has Installments");
        Assert.IsTrue(PaymentTerms."Has Installments", 'The setup indicator must reflect the rules.');
        PaymentTermInstallment."Payment %" := 25;
        PaymentTermInstallment.Modify();
        PaymentTerms.Delete(true);
        PaymentTermInstallment.SetRange("Payment Terms Code", PaymentTerms.Code);
        Assert.IsTrue(PaymentTermInstallment.IsEmpty(), 'Deleting terms must delete their reusable rules.');

        // [WHEN] The snapshot is calculated after the source setup has been deleted.
        Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        // [THEN] The original rule is used after the source setup is removed.
        AssertLine(TempPlanLine, 10000, 100, 100, DMY2Date(31, 1, 2026));
    end;

    [Test]
    procedure RenamingTermsRetainsRuleOwnership()
    var
        PaymentTerms: Record "Payment Terms";
        NewPaymentTerms: Record "Payment Terms";
        PaymentTermInstallment: Record "Payment Term Installment";
        NewCode: Code[10];
    begin
        // [FEATURE] [Installments] [Calculation]
        // [SCENARIO] Installment rules retain their ownership when payment terms are renamed.
        // [GIVEN] Payment terms with an installment rule and an available replacement code.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateSetupRule(PaymentTermInstallment, PaymentTerms.Code);
        LibraryERM.CreatePaymentTerms(NewPaymentTerms);
        NewCode := NewPaymentTerms.Code;
        NewPaymentTerms.Delete(true);

        // [WHEN] The payment terms are renamed.
        PaymentTerms.Rename(NewCode);

        // [THEN] The installment rule belongs to the new payment terms code.
        Assert.IsTrue(PaymentTermInstallment.Get(NewCode, 10000), 'Related rules must follow the renamed payment terms.');
    end;

    local procedure AddPercentageRule(var TempPlanLine: Record "Installment Calculation Line" temporary; LineNo: Integer; PaymentPercentage: Decimal; DueDateFormula: Text)
    var
        PlanID: Guid;
    begin
        TempPlanLine.Reset();
        if TempPlanLine.FindFirst() then
            PlanID := TempPlanLine."Plan ID"
        else
            PlanID := CreateGuid();
        TempPlanLine.Init();
        TempPlanLine."Plan ID" := PlanID;
        TempPlanLine."Line No." := LineNo;
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::Percentage;
        TempPlanLine."Payment %" := PaymentPercentage;
        if DueDateFormula <> '' then
            Evaluate(TempPlanLine."Due Date Calculation", DueDateFormula);
        TempPlanLine.Insert();
    end;

    local procedure SetDiscount(var TempPlanLine: Record "Installment Calculation Line" temporary; DiscountPercentage: Decimal; DiscountDateFormula: Text)
    begin
        TempPlanLine."Discount %" := DiscountPercentage;
        Evaluate(TempPlanLine."Discount Date Calculation", DiscountDateFormula);
        TempPlanLine.Modify();
    end;

    local procedure Calculate(var TempPlanLine: Record "Installment Calculation Line" temporary; Amount: Decimal; AmountLCY: Decimal; AmountRoundingPrecision: Decimal; LCYAmountRoundingPrecision: Decimal)
    var
        GracePeriod: DateFormula;
    begin
        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(1, 1, 2026),
            Amount, AmountLCY, AmountRoundingPrecision, LCYAmountRoundingPrecision, GracePeriod);
    end;

    local procedure AssertLine(var TempPlanLine: Record "Installment Calculation Line" temporary; LineNo: Integer; Amount: Decimal; AmountLCY: Decimal; DueDate: Date)
    begin
        TempPlanLine.SetRange("Line No.", LineNo);
        TempPlanLine.FindFirst();
        Assert.AreEqual(Amount, TempPlanLine.Amount, 'Unexpected installment amount.');
        Assert.AreEqual(AmountLCY, TempPlanLine."Amount (LCY)", 'Unexpected installment LCY amount.');
        Assert.AreEqual(DueDate, TempPlanLine."Due Date", 'Unexpected installment due date.');
        Assert.AreEqual(LineNo div 10000, TempPlanLine."Installment No.", 'Installments must be sequenced in rule order.');
        TempPlanLine.Reset();
    end;

    local procedure CreateSetupRule(var PaymentTermInstallment: Record "Payment Term Installment"; PaymentTermsCode: Code[10])
    begin
        PaymentTermInstallment.Init();
        PaymentTermInstallment."Payment Terms Code" := PaymentTermsCode;
        PaymentTermInstallment."Line No." := 10000;
        PaymentTermInstallment."Payment %" := 100;
        Evaluate(PaymentTermInstallment."Due Date Calculation", '<30D>');
        PaymentTermInstallment.Insert(true);
    end;
}
