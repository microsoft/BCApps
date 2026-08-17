// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Automation;
using System.TestLibraries.Utilities;

codeunit 148313 "Expense Mileage Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption, %2 = Expected Value, %3 = Table Caption';

    [Test]
    procedure GetEffectiveDistanceReturnsDoubleWhenRoundTrip()
    var
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        Mileage: Decimal;
        Result: Decimal;
    begin
        // [SCENARIO] GetEffectiveDistance returns double mileage when RoundTrip is true.
        Initialize();

        // [GIVEN] A mileage value.
        Mileage := LibraryRandom.RandDec(100, 2);

        // [WHEN] GetEffectiveDistance is called with RoundTrip = true.
        Result := ExpenseAutoPopulation.GetEffectiveDistance(Mileage, true);

        // [THEN] Result is double the mileage.
        Assert.AreEqual(Mileage * 2, Result, 'GetEffectiveDistance should double mileage for round trip');
    end;

    [Test]
    procedure GetEffectiveDistanceReturnsSameWhenNotRoundTrip()
    var
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        Mileage: Decimal;
        Result: Decimal;
    begin
        // [SCENARIO] GetEffectiveDistance returns same mileage when RoundTrip is false.
        Initialize();

        // [GIVEN] A mileage value.
        Mileage := LibraryRandom.RandDec(100, 2);

        // [WHEN] GetEffectiveDistance is called with RoundTrip = false.
        Result := ExpenseAutoPopulation.GetEffectiveDistance(Mileage, false);

        // [THEN] Result equals the original mileage.
        Assert.AreEqual(Mileage, Result, 'GetEffectiveDistance should return same mileage when not round trip');
    end;

    [Test]
    procedure GetEffectiveDistanceReturnsZeroWhenMileageIsZero()
    var
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
    begin
        // [SCENARIO] GetEffectiveDistance returns 0 when mileage is 0, regardless of RoundTrip.
        Initialize();

        // [WHEN] GetEffectiveDistance is called with 0 mileage.
        // [THEN] Result is 0 for both round trip and non-round trip.
        Assert.AreEqual(0, ExpenseAutoPopulation.GetEffectiveDistance(0, true), 'GetEffectiveDistance should return 0 for zero mileage with round trip');
        Assert.AreEqual(0, ExpenseAutoPopulation.GetEffectiveDistance(0, false), 'GetEffectiveDistance should return 0 for zero mileage without round trip');
    end;

    [Test]
    procedure MileageAmountCalculatedWithRoundTripOnExpense()
    var
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        Mileage: Decimal;
        StandardRate: Decimal;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] When Round Trip is true on a mileage expense, the amount uses effective distance (mileage x 2).
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        StandardRate := LibraryRandom.RandIntInRange(1, 5);
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", StandardRate);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create a mileage expense.
        Mileage := LibraryRandom.RandDec(50, 2);
        CreateMileageExpense(Expense, Mileage);

        // [WHEN] Set Round Trip to true and apply rule.
        Expense.Validate("Round Trip", true);
        Expense.Modify();

        // [THEN] Amount = Mileage * 2 * StandardRate.
        Expense.Get(Expense."No.");
        ExpectedAmount := Mileage * 2 * ExpenseAutoPopulation.GetStandardRateOfMileage(
            Expense."Expense Date", Expense."Currency Code", Expense."Currency Factor", StandardRate);
        Assert.AreEqual(
            ExpectedAmount,
            Expense.Amount,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Amount), ExpectedAmount, Expense.TableCaption()));
    end;

    [Test]
    procedure MileageAmountCalculatedWithoutRoundTripOnExpense()
    var
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        Mileage: Decimal;
        StandardRate: Decimal;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] When Round Trip is false on a mileage expense, the amount uses mileage directly.
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        StandardRate := LibraryRandom.RandIntInRange(1, 5);
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", StandardRate);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create a mileage expense (Round Trip defaults to false).
        Mileage := LibraryRandom.RandDec(50, 2);
        CreateMileageExpense(Expense, Mileage);

        // [THEN] Amount = Mileage * StandardRate.
        Expense.Get(Expense."No.");
        ExpectedAmount := Mileage * ExpenseAutoPopulation.GetStandardRateOfMileage(
            Expense."Expense Date", Expense."Currency Code", Expense."Currency Factor", StandardRate);
        Assert.AreEqual(
            ExpectedAmount,
            Expense.Amount,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Amount), ExpectedAmount, Expense.TableCaption()));
    end;

    [Test]
    procedure RoundTripCopiedToExpenseReportLine()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        // [SCENARIO] Round Trip value is preserved on Expense Report Line when set directly.
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create a mileage expense with Round Trip = true.
        CreateMileageExpense(Expense, LibraryRandom.RandDec(50, 2));
        Expense.Validate("Round Trip", true);
        Expense.Modify();

        // [GIVEN] Create an expense report with a mileage line.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, Expense."Expense User No.", Expense."Expense Category", ExpensePaymentMethod.Code, true, '', 0);

        // [WHEN] Set Round Trip to true on the report line (simulating copy from expense).
        ExpenseReportLine.Validate(Mileage, Expense.Mileage);
        ExpenseReportLine.Validate("Round Trip", true);
        ExpenseReportLine.Modify();

        // [THEN] Expense Report Line has Round Trip = true.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            true,
            ExpenseReportLine."Round Trip",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Round Trip"), true, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure MileageFieldsClearedWhenCategoryChangedFromMileage()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] Mileage, Round Trip, Starting Point, and Ending Point are cleared when category changes from Mileage.
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create a mileage expense with all fields filled.
        CreateMileageExpense(Expense, LibraryRandom.RandDec(50, 2));
        Expense.Validate("Round Trip", true);
        Expense.Validate("Starting Point", 'Point A');
        Expense.Validate("Ending Point", 'Point B');
        Expense.Modify();

        // [GIVEN] Create a non-mileage category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");

        // [WHEN] Change expense category to the non-mileage category.
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Modify();

        // [THEN] All mileage-related fields are cleared.
        Assert.AreEqual(0, Expense.Mileage, 'Mileage should be 0 after category change');
        Assert.AreEqual(false, Expense."Round Trip", 'Round Trip should be false after category change');
        Assert.AreEqual('', Expense."Starting Point", 'Starting Point should be empty after category change');
        Assert.AreEqual('', Expense."Ending Point", 'Ending Point should be empty after category change');
    end;

    [Test]
    procedure MileageFieldsClearedOnExpenseReportLineWhenCategoryChanged()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        MileageCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        // [SCENARIO] Mileage-related fields are cleared on Expense Report Line when category changes from Mileage.
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create expense report with mileage line.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(MileageCategory, MileageCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Mileage);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", MileageCategory.Code, ExpensePaymentMethod.Code, true, '', 0);

        // [GIVEN] Set mileage fields.
        ExpenseReportLine.Validate(Mileage, LibraryRandom.RandDec(50, 2));
        ExpenseReportLine.Validate("Round Trip", true);
        ExpenseReportLine."Starting Point" := 'Point A';
        ExpenseReportLine."Ending Point" := 'Point B';
        ExpenseReportLine.Modify();

        // [GIVEN] Create a non-mileage category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");

        // [WHEN] Change the category.
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory.Code);
        ExpenseReportLine.Modify();

        // [THEN] All mileage-related fields are cleared.
        Assert.AreEqual(0, ExpenseReportLine.Mileage, 'Mileage should be 0 after category change');
        Assert.AreEqual(false, ExpenseReportLine."Round Trip", 'Round Trip should be false after category change');
        Assert.AreEqual('', ExpenseReportLine."Starting Point", 'Starting Point should be empty after category change');
        Assert.AreEqual('', ExpenseReportLine."Ending Point", 'Ending Point should be empty after category change');
    end;

    [Test]
    procedure MileageAmountCalculatedWithRoundTripOnExpenseReportLine()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        Mileage: Decimal;
        StandardRate: Decimal;
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] When Round Trip is true on an expense report line, the amount uses effective distance.
        Initialize();

        // [GIVEN] Set up Standard Rate of Mileage.
        ExpenseAgentSetup.Get();
        StandardRate := LibraryRandom.RandIntInRange(1, 5);
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", StandardRate);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create expense report with mileage line.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Mileage);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', 0);

        // [GIVEN] Set mileage.
        Mileage := LibraryRandom.RandDec(50, 2);
        ExpenseReportLine.Validate(Mileage, Mileage);
        ExpenseReportLine.Modify();

        // [WHEN] Set Round Trip to true.
        ExpenseReportLine.Validate("Round Trip", true);
        ExpenseReportLine.Modify();

        // [THEN] Amount = Mileage * 2 * StandardRate.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        ExpectedAmount := Mileage * 2 * ExpenseAutoPopulation.GetStandardRateOfMileage(
            ExpenseReportLine."Expense Date", ExpenseReportLine."Expense Currency Code",
            ExpenseReportLine."Expense Currency Factor", StandardRate);
        Assert.AreEqual(
            ExpectedAmount,
            ExpenseReportLine.Amount,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Amount), ExpectedAmount, ExpenseReportLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Mileage Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Mileage Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Mileage Test");
    end;

    local procedure CreateMileageExpense(var Expense: Record Expense; Mileage: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Mileage);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 0);

        Expense.Validate(Mileage, Mileage);
        Expense.Modify();
    end;
}
