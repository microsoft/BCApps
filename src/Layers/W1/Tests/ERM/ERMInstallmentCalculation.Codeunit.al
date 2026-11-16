// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

codeunit 134491 "ERM Installment Calculation"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        InstallmentCalculation: Codeunit "Installment Calculation";

    [Test]
    procedure PercentagesUseOriginalTotalsAndDocumentDate()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 30000, 40, '<90D>');
        AddPercentageRule(TempPlanLine, 10000, 30, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 30, '<60D>');

        Calculate(TempPlanLine, 10000, 12345, 0.01, 0.01);

        AssertLine(TempPlanLine, 10000, 3000, 3703.5, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 3000, 3703.5, DMY2Date(2, 3, 2026));
        AssertLine(TempPlanLine, 30000, 4000, 4938, DMY2Date(1, 4, 2026));
    end;

    [Test]
    procedure FinalLineReceivesIndependentCurrencyResiduals()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 33.33333, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 33.33333, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 33.33334, '<90D>');

        Calculate(TempPlanLine, 10000, 10.01, 0.01, 0.01);

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
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 25, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 25, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 0, '<90D>');
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        TempPlanLine.Modify();

        Calculate(TempPlanLine, 100, 123.45, 0.01, 0.01);

        AssertLine(TempPlanLine, 30000, 50, 61.73, DMY2Date(1, 4, 2026));
    end;

    [Test]
    procedure UsesWholeUnitAndThreeDecimalPrecisions()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');

        Calculate(TempPlanLine, 101, 1.001, 1, 0.001);
        AssertLine(TempPlanLine, 10000, 51, 0.501, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 50, 0.5, DMY2Date(2, 3, 2026));

        Calculate(TempPlanLine, 1.001, 101, 0.001, 1);
        AssertLine(TempPlanLine, 10000, 0.501, 51, DMY2Date(31, 1, 2026));
        AssertLine(TempPlanLine, 20000, 0.5, 50, DMY2Date(2, 3, 2026));
    end;

    [Test]
    procedure DiscountsUseEachLineAndPostingDateGracePeriod()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
        GracePeriod: DateFormula;
    begin
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        SetDiscount(TempPlanLine, 2, '<10D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        SetDiscount(TempPlanLine, 1, '<15D>');
        Evaluate(GracePeriod, '<5D>');

        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(16, 1, 2026), 100, 100, 0.01, 0.01, GracePeriod);

        TempPlanLine.FindFirst();
        Assert.AreEqual(DMY2Date(11, 1, 2026), TempPlanLine."Pmt. Discount Date", 'Discount date must use the document date.');
        Assert.AreEqual(1, TempPlanLine."Original Pmt. Disc. Possible", 'The last grace day must remain eligible.');
        TempPlanLine.Next();
        Assert.AreEqual(0.5, TempPlanLine."Original Pmt. Disc. Possible", 'Each line must use its own discount percentage.');

        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(17, 1, 2026), 100, 100, 0.01, 0.01, GracePeriod);

        TempPlanLine.FindFirst();
        Assert.AreEqual(0, TempPlanLine."Original Pmt. Disc. Possible", 'Expired eligibility must be cleared on recalculation.');
        TempPlanLine.Next();
        Assert.AreEqual(0.5, TempPlanLine."Original Pmt. Disc. Possible", 'Later discount eligibility must be retained.');
    end;

    [Test]
    procedure ZeroLCYAllocationDoesNotCreateDiscountEligibility()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        SetDiscount(TempPlanLine, 2, '<10D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        SetDiscount(TempPlanLine, 2, '<10D>');

        Calculate(TempPlanLine, 100, 0.01, 0.01, 0.01);

        TempPlanLine.FindFirst();
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
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 33.33, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 33.33, '<60D>');
        AddPercentageRule(TempPlanLine, 30000, 33.33, '<90D>');

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('percentages must total 100');
    end;

    [Test]
    procedure RejectsRemainingAmountBeforeFinalLine()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 0, '<30D>');
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        TempPlanLine.Modify();
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('Check line 10000');
    end;

    [Test]
    procedure RejectsMissingDueDateFormula()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 100, '');

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('Due Date Calculation must be specified on installment line 10000');
    end;

    [Test]
    procedure RejectsDescendingDatesWithoutReplacingSnapshot()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 50, '<60D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<30D>');

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('due date on installment line 20000');
        TempPlanLine.FindFirst();
        Assert.AreEqual(0, TempPlanLine.Amount, 'A failed calculation must not partially replace the snapshot.');
        Assert.AreEqual(0, TempPlanLine."Installment No.", 'A failed calculation must not assign partial sequence values.');
    end;

    [Test]
    procedure RejectsDiscountDateAfterDueDate()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');
        SetDiscount(TempPlanLine, 2, '<31D>');

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('payment discount date on installment line 10000');
    end;

    [Test]
    procedure RejectsZeroRoundedInstallment()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 1, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 99, '<60D>');

        asserterror Calculate(TempPlanLine, 0.01, 0.01, 0.01, 0.01);

        Assert.ExpectedError('Installment line 10000 must have a positive amount');
    end;

    [Test]
    procedure RejectsInvalidRoundingPrecision()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');

        asserterror Calculate(TempPlanLine, 100, 100, 0, 0.01);

        Assert.ExpectedError('rounding precisions must be greater than zero');
    end;

    [Test]
    procedure RejectsMultiplePlansInOneCalculation()
    var
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        AddPercentageRule(TempPlanLine, 10000, 50, '<30D>');
        AddPercentageRule(TempPlanLine, 20000, 50, '<60D>');
        TempPlanLine.Rename(CreateGuid(), TempPlanLine."Line No.");

        asserterror Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('same nonempty plan');
    end;

    [Test]
    procedure RejectsPersistentCalculationTarget()
    var
        PlanLine: Record "Installment Plan Line";
    begin
        asserterror Calculate(PlanLine, 100, 100, 0.01, 0.01);

        Assert.ExpectedError('requires a temporary plan line record');
    end;

    [Test]
    procedure OrdinaryTermsProduceNoSyntheticPlan()
    var
        PaymentTerms: Record "Payment Terms";
        TempPlanLine: Record "Installment Plan Line" temporary;
        OriginalDueDateCalculation: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        OriginalDueDateCalculation := PaymentTerms."Due Date Calculation";
        AddPercentageRule(TempPlanLine, 10000, 100, '<30D>');

        Assert.IsFalse(
            InstallmentCalculation.CopyPaymentTerms(PaymentTerms.Code, CreateGuid(), TempPlanLine),
            'Ordinary terms must not create installment lines.');

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
        PlanLine: Record "Installment Plan Line";
        TempPlanLine: Record "Installment Plan Line" temporary;
        PlanID: Guid;
    begin
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

        Calculate(TempPlanLine, 100, 100, 0.01, 0.01);

        AssertLine(TempPlanLine, 10000, 100, 100, DMY2Date(31, 1, 2026));
        PlanLine.SetRange("Plan ID", PlanID);
        Assert.IsTrue(PlanLine.IsEmpty(), 'Copying and calculating rules must not persist a plan.');
    end;

    [Test]
    procedure RenamingTermsRetainsRuleOwnership()
    var
        PaymentTerms: Record "Payment Terms";
        NewPaymentTerms: Record "Payment Terms";
        PaymentTermInstallment: Record "Payment Term Installment";
        NewCode: Code[10];
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateSetupRule(PaymentTermInstallment, PaymentTerms.Code);
        LibraryERM.CreatePaymentTerms(NewPaymentTerms);
        NewCode := NewPaymentTerms.Code;
        NewPaymentTerms.Delete(true);

        PaymentTerms.Rename(NewCode);

        Assert.IsTrue(PaymentTermInstallment.Get(NewCode, 10000), 'Related rules must follow the renamed payment terms.');
    end;

    local procedure AddPercentageRule(var TempPlanLine: Record "Installment Plan Line" temporary; LineNo: Integer; PaymentPercentage: Decimal; DueDateFormula: Text)
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

    local procedure SetDiscount(var TempPlanLine: Record "Installment Plan Line" temporary; DiscountPercentage: Decimal; DiscountDateFormula: Text)
    begin
        TempPlanLine."Discount %" := DiscountPercentage;
        Evaluate(TempPlanLine."Discount Date Calculation", DiscountDateFormula);
        TempPlanLine.Modify();
    end;

    local procedure Calculate(var TempPlanLine: Record "Installment Plan Line" temporary; Amount: Decimal; AmountLCY: Decimal; AmountRoundingPrecision: Decimal; LCYAmountRoundingPrecision: Decimal)
    var
        GracePeriod: DateFormula;
    begin
        InstallmentCalculation.Calculate(
            TempPlanLine, DMY2Date(1, 1, 2026), DMY2Date(1, 1, 2026),
            Amount, AmountLCY, AmountRoundingPrecision, LCYAmountRoundingPrecision, GracePeriod);
    end;

    local procedure AssertLine(var TempPlanLine: Record "Installment Plan Line" temporary; LineNo: Integer; Amount: Decimal; AmountLCY: Decimal; DueDate: Date)
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
