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
        CannotbeBeforeLbl: Label 'cannot be before';
        OverlapsWithMileageRateLbl: Label 'overlaps with mileage rate';
        MileageRateEffectiveOnStartingDateLbl: Label 'Mileage rate should be effective on its starting date';
        UnexpectedMileageRateOnStartingDateLbl: Label 'Unexpected mileage rate on the starting date';
        MileageRateEffectiveOnEndingDateLbl: Label 'Mileage rate should be effective on its ending date';
        UnexpectedMileageRateOnEndingDateLbl: Label 'Unexpected mileage rate on the ending date';
        VehicleSpecificMileageRateNotUsedLbl: Label 'The vehicle-specific mileage rate should be used';
        GenericMileageRateUsedLbl: Label 'The standard mileage rate should be used when no rate matches the vehicle type';
        ChangingVehicleTypeShouldRecalculateAmountLbl: Label 'Changing vehicle type should recalculate the mileage amount';
        ReportLineVehicleSpecificMileageRateLbl: Label 'The report line should use the vehicle-specific mileage rate';

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

    [Test]
    procedure MileageRateRequiresStartingDate()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
    begin
        // [SCENARIO 638119] A mileage rate cannot be created without a starting date.
        Initialize();

        // [GIVEN] A mileage rate without a starting date.
        MileageRateSetup.Init();
        MileageRateSetup.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(MileageRateSetup.Code));
        MileageRateSetup.Rate := LibraryRandom.RandDec(10, 2);

        // [WHEN] The mileage rate is inserted.
        asserterror MileageRateSetup.Insert(true);

        // [THEN] The missing starting date error is raised.
        Assert.ExpectedError(MileageRateSetup.FieldCaption("Starting Date"));
    end;

    [Test]
    procedure MileageRateEndingDateCannotBeBeforeStartingDate()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
    begin
        // [SCENARIO 638119] A mileage rate cannot end before it starts.
        Initialize();

        // [GIVEN] A mileage rate with a starting date.
        MileageRateSetup.Init();
        MileageRateSetup.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(MileageRateSetup.Code));
        MileageRateSetup.Validate("Starting Date", WorkDate());

        // [WHEN] The ending date is set before the starting date.
        asserterror MileageRateSetup.Validate("Ending Date", WorkDate() - 1);

        // [THEN] The invalid date range error is raised.
        Assert.ExpectedError(CannotbeBeforeLbl);
    end;

    [Test]
    procedure MileageRateDateRangesCannotOverlap()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] Mileage rates for the same currency and vehicle type cannot have overlapping date ranges.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] A mileage rate effective for a closed date range.
        CreateMileageRate(MileageRateSetup, WorkDate(), WorkDate() + 10, '', VehicleTypeCode, LibraryRandom.RandDec(10, 2));

        // [WHEN] Another rate starts on the first rate's ending date.
        MileageRateSetup.Init();
        MileageRateSetup.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(MileageRateSetup.Code));
        MileageRateSetup."Vehicle Type" := VehicleTypeCode;
        MileageRateSetup."Starting Date" := WorkDate() + 10;
        MileageRateSetup."Ending Date" := WorkDate() + 20;
        MileageRateSetup.Rate := LibraryRandom.RandDec(10, 2);
        asserterror MileageRateSetup.Insert(true);

        // [THEN] The inclusive boundary is detected as an overlap.
        Assert.ExpectedError(OverlapsWithMileageRateLbl);
    end;

    [Test]
    procedure MileageRateAllowsAdjacentHistoricalDateRanges()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        HistoricalRateCode: Code[20];
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO] Multiple non-overlapping historical mileage rates can be maintained.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] A historical mileage rate.
        CreateMileageRate(MileageRateSetup, WorkDate() - 20, WorkDate() - 10, '', VehicleTypeCode, LibraryRandom.RandDec(10, 2));
        HistoricalRateCode := MileageRateSetup.Code;

        // [WHEN] A new rate starts the day after the historical rate ends.
        CreateMileageRate(MileageRateSetup, WorkDate() - 9, 0D, '', VehicleTypeCode, LibraryRandom.RandDec(10, 2));

        // [THEN] Both mileage rates exist.
        MileageRateSetup.SetFilter(Code, '%1|%2', HistoricalRateCode, MileageRateSetup.Code);
        Assert.RecordCount(MileageRateSetup, 2);
    end;

    [Test]
    procedure FindEffectiveMileageRateIncludesDateRangeBoundaries()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        StartingDate: Date;
        EndingDate: Date;
        Rate: Decimal;
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO] A mileage rate is effective on both its starting and ending dates.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] A vehicle-specific mileage rate with a closed date range.
        StartingDate := WorkDate() - 5;
        EndingDate := WorkDate() + 5;
        Rate := LibraryRandom.RandDec(10, 2);
        CreateMileageRate(MileageRateSetup, StartingDate, EndingDate, '', VehicleTypeCode, Rate);

        // [WHEN] The effective rate is found on each date range boundary.
        // [THEN] The configured rate is returned on both dates.
        Assert.IsTrue(MileageRateSetup.FindEffectiveRate(StartingDate, '', VehicleTypeCode), MileageRateEffectiveOnStartingDateLbl);
        Assert.AreEqual(Rate, MileageRateSetup.Rate, UnexpectedMileageRateOnStartingDateLbl);
        Assert.IsTrue(MileageRateSetup.FindEffectiveRate(EndingDate, '', VehicleTypeCode), MileageRateEffectiveOnEndingDateLbl);
        Assert.AreEqual(Rate, MileageRateSetup.Rate, UnexpectedMileageRateOnEndingDateLbl);
    end;

    [Test]
    procedure MileageAmountUsesVehicleSpecificRate()
    var
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MileageRateSetup: Record "Mileage Rate Setup";
        Mileage: Decimal;
        Rate: Decimal;
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] A mileage expense uses the effective rate for its vehicle type.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] An effective vehicle-specific mileage rate and a different standard rate.
        Rate := LibraryRandom.RandIntInRange(2, 5);
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', VehicleTypeCode, Rate);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", Rate + 1);
        ExpenseAgentSetup.Modify();

        // [GIVEN] A mileage expense.
        Mileage := LibraryRandom.RandDec(50, 2);
        CreateMileageExpense(Expense, Mileage);

        // [WHEN] The vehicle type is set to the vehicle-specific type.
        Expense.Validate("Vehicle Type", VehicleTypeCode);
        Expense.Modify();

        // [THEN] The expense amount uses the car rate.
        Assert.AreEqual(Mileage * Rate, Expense.Amount, VehicleSpecificMileageRateNotUsedLbl);
    end;

    [Test]
    procedure MileageAmountFallsBackToGenericRateForVehicleType()
    var
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MileageRateSetup: Record "Mileage Rate Setup";
        Mileage: Decimal;
        GenericRate: Decimal;
    begin
        // [SCENARIO 638122] A mileage expense uses the standard rate when no rate exists for its vehicle type.
        Initialize();

        // [GIVEN] An effective generic mileage rate and no rate for the expense's vehicle type.
        GenericRate := LibraryRandom.RandIntInRange(2, 5);
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', '', GenericRate);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", GenericRate + 1);
        ExpenseAgentSetup.Modify();

        // [GIVEN] A mileage expense.
        Mileage := LibraryRandom.RandDec(50, 2);
        CreateMileageExpense(Expense, Mileage);

        // [WHEN] The vehicle type is set to a type without a specific rate.
        Expense.Validate("Vehicle Type", CreateVehicleType());
        Expense.Modify();

        // [THEN] The expense amount uses the generic mileage rate.
        Assert.AreEqual(Mileage * (GenericRate + 1), Expense.Amount, GenericMileageRateUsedLbl);
    end;

    [Test]
    procedure ChangingVehicleTypeRecalculatesMileageAmount()
    var
        Expense: Record Expense;
        MileageRateSetup: Record "Mileage Rate Setup";
        Mileage: Decimal;
        CarRate: Decimal;
        VanRate: Decimal;
        CarVehicleTypeCode: Code[20];
        VanVehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] Changing the vehicle type recalculates the mileage expense amount.
        Initialize();
        CarVehicleTypeCode := CreateVehicleType();
        VanVehicleTypeCode := CreateVehicleType();

        // [GIVEN] Different effective mileage rates for two vehicle types.
        CarRate := LibraryRandom.RandIntInRange(1, 4);
        VanRate := CarRate + 1;
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', CarVehicleTypeCode, CarRate);
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', VanVehicleTypeCode, VanRate);

        // [GIVEN] A mileage expense for the first vehicle type.
        Mileage := LibraryRandom.RandDec(50, 2);
        CreateMileageExpense(Expense, Mileage);
        Expense.Validate("Vehicle Type", CarVehicleTypeCode);
        Expense.Modify();

        // [WHEN] The vehicle type is changed to the second vehicle type.
        Expense.Validate("Vehicle Type", VanVehicleTypeCode);
        Expense.Modify();

        // [THEN] The expense amount uses the van rate.
        Assert.AreEqual(Mileage * VanRate, Expense.Amount, ChangingVehicleTypeShouldRecalculateAmountLbl);
    end;

    [Test]
    procedure OpenEndedMileageRateOverlapsLaterRate()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] An open-ended mileage rate overlaps any later rate for the same currency and vehicle type.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] An open-ended mileage rate.
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', VehicleTypeCode, LibraryRandom.RandDec(10, 2));

        // [WHEN] A later mileage rate for the same vehicle type is inserted.
        MileageRateSetup.Init();
        MileageRateSetup.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(MileageRateSetup.Code));
        MileageRateSetup."Vehicle Type" := VehicleTypeCode;
        MileageRateSetup."Starting Date" := WorkDate() + 1;
        MileageRateSetup.Rate := LibraryRandom.RandDec(10, 2);
        asserterror MileageRateSetup.Insert(true);

        // [THEN] The open-ended overlap is rejected.
        Assert.ExpectedError(OverlapsWithMileageRateLbl);
    end;

    [Test]
    procedure MileageRatesWithDifferentCurrencyOrVehicleTypeCanShareDates()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        CarVehicleTypeCode: Code[20];
        VanVehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] Date ranges are scoped by currency and vehicle type.
        Initialize();
        CarVehicleTypeCode := CreateVehicleType();
        VanVehicleTypeCode := CreateVehicleType();

        // [GIVEN] A local-currency mileage rate for the first vehicle type.
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', CarVehicleTypeCode, LibraryRandom.RandDec(10, 2));

        // [WHEN] Rates with the same dates but another currency or vehicle type are inserted.
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, 'EUR', CarVehicleTypeCode, LibraryRandom.RandDec(10, 2));
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', VanVehicleTypeCode, LibraryRandom.RandDec(10, 2));

        // [THEN] All three mileage rates exist.
        MileageRateSetup.Reset();
        Assert.RecordCount(MileageRateSetup, 3);
    end;

    [Test]
    procedure MileageReportLineAmountUsesVehicleSpecificRate()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpensePaymentMethod: Record "Expense Payment Method";
        MileageRateSetup: Record "Mileage Rate Setup";
        Mileage: Decimal;
        Rate: Decimal;
        VehicleTypeCode: Code[20];
    begin
        // [SCENARIO 638122] A mileage expense report line uses the effective rate for its vehicle type.
        Initialize();
        VehicleTypeCode := CreateVehicleType();

        // [GIVEN] An effective vehicle-specific mileage rate.
        Rate := LibraryRandom.RandIntInRange(2, 5);
        CreateMileageRate(MileageRateSetup, WorkDate(), 0D, '', VehicleTypeCode, Rate);

        // [GIVEN] An expense report with a mileage line.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Mileage);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', 0);

        // [WHEN] Mileage and the vehicle type are entered.
        Mileage := LibraryRandom.RandDec(50, 2);
        ExpenseReportLine.Validate(Mileage, Mileage);
        ExpenseReportLine.Validate("Vehicle Type", VehicleTypeCode);
        ExpenseReportLine.Modify();

        // [THEN] The report line amount uses the truck rate.
        Assert.AreEqual(Mileage * Rate, ExpenseReportLine.Amount, ReportLineVehicleSpecificMileageRateLbl);
    end;

    local procedure Initialize()
    var
        MileageRateSetup: Record "Mileage Rate Setup";
        ExpenseVehicleType: Record "Expense Vehicle Type";
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Mileage Test");
        LibraryExpense.CleanUpBeforeTesting();
        MileageRateSetup.DeleteAll();
        ExpenseVehicleType.DeleteAll();
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

    local procedure CreateMileageRate(var MileageRateSetup: Record "Mileage Rate Setup"; StartingDate: Date; EndingDate: Date; CurrencyCode: Code[10]; VehicleType: Code[20]; Rate: Decimal)
    begin
        MileageRateSetup.Init();
        MileageRateSetup.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(MileageRateSetup.Code));
        MileageRateSetup."Currency Code" := CurrencyCode;
        MileageRateSetup.Rate := Rate;
        MileageRateSetup."Starting Date" := StartingDate;
        MileageRateSetup."Ending Date" := EndingDate;
        MileageRateSetup."Vehicle Type" := VehicleType;
        MileageRateSetup.Insert(true);
    end;

    local procedure CreateVehicleType(): Code[20]
    var
        ExpenseVehicleType: Record "Expense Vehicle Type";
    begin
        ExpenseVehicleType.Init();
        ExpenseVehicleType.Code := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ExpenseVehicleType.Code));
        ExpenseVehicleType.Insert(true);
        exit(ExpenseVehicleType.Code);
    end;
}
