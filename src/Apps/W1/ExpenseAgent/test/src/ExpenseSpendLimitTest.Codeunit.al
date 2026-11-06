// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Period;

codeunit 148363 "Expense Spend Limit Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        AmountMustNotBeNegativeErr: Label '%1 must not be negative.', Comment = '%1 = Amount field caption';
        NoAccountingPeriodErr: Label 'No accounting period is defined for %1.', Comment = '%1 = date';
        AccountingPeriodHasNoEndErr: Label 'The accounting period starting on %1 has no end date.', Comment = '%1 = starting date of the accounting period';
        OverlappingSpendLimitErr: Label 'Spend limit %1 for the period %2..%3 already exists', Comment = '%1 = spend limit No., %2 = start date, %3 = end date';

    // =========================================================================
    // Period calculation
    // =========================================================================

    [Test]
    procedure PeriodTypeMonthSetsStartAndEndOfMonth()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] Period Type Month aligns Start Date and End Date with the calendar month.
        Initialize();

        // [WHEN] Period Type = Month and Start Date is a date within a month.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Month);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());

        // [THEN] Start Date and End Date are the first and last day of that month.
        Assert.AreEqual(CalcDate('<-CM>', WorkDate()), ExpenseSpendLimit."Start Date", ExpenseSpendLimit.FieldCaption("Start Date"));
        Assert.AreEqual(CalcDate('<CM>', WorkDate()), ExpenseSpendLimit."End Date", ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    [Test]
    procedure PeriodTypeQuarterSetsStartAndEndOfQuarter()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] Period Type Quarter aligns Start Date and End Date with the calendar quarter.
        Initialize();

        // [WHEN] Period Type = Quarter and Start Date is a date within a quarter.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Quarter);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());

        // [THEN] Start Date and End Date are the first and last day of that quarter.
        Assert.AreEqual(CalcDate('<-CQ>', WorkDate()), ExpenseSpendLimit."Start Date", ExpenseSpendLimit.FieldCaption("Start Date"));
        Assert.AreEqual(CalcDate('<CQ>', WorkDate()), ExpenseSpendLimit."End Date", ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    [Test]
    procedure PeriodTypeYearSetsStartAndEndOfYear()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] Period Type Year aligns Start Date and End Date with the calendar year.
        Initialize();

        // [WHEN] Period Type = Year and Start Date is a date within a year.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Year);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());

        // [THEN] Start Date and End Date are the first and last day of that year.
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), ExpenseSpendLimit."Start Date", ExpenseSpendLimit.FieldCaption("Start Date"));
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), ExpenseSpendLimit."End Date", ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    [Test]
    procedure ChangingPeriodTypeRecalculatesPeriodDates()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] Changing Period Type after Start Date is set recalculates the period dates.
        Initialize();

        // [GIVEN] A spend limit with Period Type = Month and Start Date set.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Month);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());

        // [WHEN] Period Type is changed to Year.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Year);

        // [THEN] Start Date and End Date are recalculated for the year.
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), ExpenseSpendLimit."Start Date", ExpenseSpendLimit.FieldCaption("Start Date"));
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), ExpenseSpendLimit."End Date", ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    [Test]
    procedure PeriodTypeAccountingPeriodUsesAccountingPeriodBoundaries()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        PeriodStartDate: Date;
        NextPeriodStartDate: Date;
    begin
        // [SCENARIO 617064] Period Type Accounting Period uses the boundaries of the accounting period that contains the Start Date.
        Initialize();

        // [GIVEN] Two consecutive accounting periods.
        PeriodStartDate := DMY2Date(1, 1, 2200);
        NextPeriodStartDate := DMY2Date(1, 2, 2200);
        MockAccountingPeriod(PeriodStartDate);
        MockAccountingPeriod(NextPeriodStartDate);

        // [WHEN] Period Type = Accounting Period and Start Date is within the first period.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::"Accounting Period");
        ExpenseSpendLimit.Validate("Start Date", DMY2Date(15, 1, 2200));

        // [THEN] Start Date is the period start and End Date is the day before the next period starts.
        Assert.AreEqual(PeriodStartDate, ExpenseSpendLimit."Start Date", ExpenseSpendLimit.FieldCaption("Start Date"));
        Assert.AreEqual(NextPeriodStartDate - 1, ExpenseSpendLimit."End Date", ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    [Test]
    procedure PeriodTypeAccountingPeriodWithoutNextPeriodFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        PeriodStartDate: Date;
    begin
        // [SCENARIO 617064] Period Type Accounting Period fails when the accounting period has no end (no following period).
        Initialize();

        // [GIVEN] The last accounting period, without a following period.
        PeriodStartDate := DMY2Date(1, 1, 2300);
        MockAccountingPeriod(PeriodStartDate);

        // [WHEN] Period Type = Accounting Period and Start Date is within that period.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::"Accounting Period");
        asserterror ExpenseSpendLimit.Validate("Start Date", DMY2Date(15, 1, 2300));

        // [THEN] An error that the accounting period has no end date is raised.
        Assert.ExpectedError(StrSubstNo(AccountingPeriodHasNoEndErr, PeriodStartDate));
    end;

    [Test]
    procedure PeriodTypeAccountingPeriodWithoutAccountingPeriodFails()
    var
        AccountingPeriod: Record "Accounting Period";
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ReferenceDate: Date;
    begin
        // [SCENARIO 617064] Period Type Accounting Period fails when no accounting period covers the Start Date.
        Initialize();

        // [GIVEN] No accounting period starts on or before the reference date.
        ReferenceDate := DMY2Date(15, 1, 1800);
        AccountingPeriod.SetFilter("Starting Date", '..%1', ReferenceDate);
        AccountingPeriod.DeleteAll();

        // [WHEN] Period Type = Accounting Period and Start Date is the reference date.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::"Accounting Period");
        asserterror ExpenseSpendLimit.Validate("Start Date", ReferenceDate);

        // [THEN] An error that no accounting period is defined is raised.
        Assert.ExpectedError(StrSubstNo(NoAccountingPeriodErr, ReferenceDate));
    end;

    // =========================================================================
    // Table validation
    // =========================================================================

    [Test]
    procedure ChangingSpendLimitTypeClearsLimitFor()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Changing Spend Limit Type clears Limit For.
        Initialize();

        // [GIVEN] A user spend limit for an Expense User.
        MockExpenseUser(ExpenseUser, '');
        ExpenseSpendLimit.Validate("Spend Limit Type", ExpenseSpendLimit."Spend Limit Type"::User);
        ExpenseSpendLimit.Validate("Limit For", ExpenseUser."No.");

        // [WHEN] Spend Limit Type is changed to Team.
        ExpenseSpendLimit.Validate("Spend Limit Type", ExpenseSpendLimit."Spend Limit Type"::Team);

        // [THEN] Limit For is cleared.
        Assert.AreEqual('', ExpenseSpendLimit."Limit For", ExpenseSpendLimit.FieldCaption("Limit For"));
    end;

    [Test]
    procedure InsertUserSpendLimitWithoutLimitForFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A user spend limit cannot be inserted without Limit For.
        Initialize();

        // [GIVEN] A user spend limit with dates and amount but without Limit For.
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, '', '', 1000);

        // [WHEN] The spend limit is inserted.
        asserterror ExpenseSpendLimit.Insert(true);

        // [THEN] A TestField error on Limit For is raised.
        Assert.ExpectedTestFieldError(ExpenseSpendLimit.FieldCaption("Limit For"), '');
    end;

    [Test]
    procedure InsertTeamSpendLimitWithoutLimitForFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A team spend limit cannot be inserted without Limit For.
        Initialize();

        // [GIVEN] A team spend limit with dates and amount but without Limit For.
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, '', '', 1000);

        // [WHEN] The spend limit is inserted.
        asserterror ExpenseSpendLimit.Insert(true);

        // [THEN] A TestField error on Limit For is raised.
        Assert.ExpectedTestFieldError(ExpenseSpendLimit.FieldCaption("Limit For"), '');
    end;

    [Test]
    procedure InsertCompanySpendLimitWithLimitForFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A company spend limit cannot be inserted with Limit For.
        Initialize();

        // [GIVEN] A company spend limit with Limit For filled in.
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1000);
        ExpenseSpendLimit."Limit For" := LibraryUtility.GenerateGUID();

        // [WHEN] The spend limit is inserted.
        asserterror ExpenseSpendLimit.Insert(true);

        // [THEN] A TestField error is raised.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure InsertSpendLimitWithoutAmountFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A spend limit cannot be inserted without Amount (LCY).
        Initialize();

        // [GIVEN] A company spend limit without amount.
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 0);

        // [WHEN] The spend limit is inserted.
        asserterror ExpenseSpendLimit.Insert(true);

        // [THEN] A TestField error on Amount (LCY) is raised.
        Assert.ExpectedTestFieldError(ExpenseSpendLimit.FieldCaption("Amount (LCY)"), '');
    end;

    [Test]
    procedure InsertSpendLimitWithoutStartDateFails()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A spend limit cannot be inserted without Start Date.
        Initialize();

        // [GIVEN] A company spend limit with amount but without dates.
        ExpenseSpendLimit.Init();
        ExpenseSpendLimit.Validate("Spend Limit Type", ExpenseSpendLimit."Spend Limit Type"::Company);
        ExpenseSpendLimit.Validate("Amount (LCY)", 1000);

        // [WHEN] The spend limit is inserted.
        asserterror ExpenseSpendLimit.Insert(true);

        // [THEN] A TestField error on Start Date is raised.
        Assert.ExpectedTestFieldError(ExpenseSpendLimit.FieldCaption("Start Date"), '');
    end;

    [Test]
    procedure NegativeAmountIsNotAllowed()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] Amount (LCY) must not be negative.
        Initialize();

        // [WHEN] A negative Amount (LCY) is validated.
        asserterror ExpenseSpendLimit.Validate("Amount (LCY)", -1);

        // [THEN] An error that the amount must not be negative is raised.
        Assert.ExpectedError(StrSubstNo(AmountMustNotBeNegativeErr, ExpenseSpendLimit.FieldCaption("Amount (LCY)")));
    end;

    [Test]
    procedure EndDateBeforeStartDateIsNotAllowed()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] End Date cannot be before Start Date.
        Initialize();

        // [GIVEN] A spend limit with period dates.
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Month);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());

        // [WHEN] End Date is set before Start Date.
        asserterror ExpenseSpendLimit.Validate("End Date", ExpenseSpendLimit."Start Date" - 1);

        // [THEN] A field error on End Date is raised.
        Assert.ExpectedError(ExpenseSpendLimit.FieldCaption("End Date"));
    end;

    // =========================================================================
    // Multiple spend limits for the same scope
    // =========================================================================

    [Test]
    procedure DuplicateSpendLimitForSamePeriodIsNotAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A second spend limit for the same user, payment method, period type and period cannot be inserted.
        Initialize();

        // [GIVEN] A monthly user spend limit "L1" for the current month.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] Another monthly user spend limit for the same user and month is inserted.
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser."No.", '', 500);
        asserterror ExpenseSpendLimit[2].Insert(true);

        // [THEN] An error referring to "L1" is raised.
        Assert.ExpectedError(StrSubstNo(OverlappingSpendLimitErr, ExpenseSpendLimit[1]."No.", ExpenseSpendLimit[1]."Start Date", ExpenseSpendLimit[1]."End Date"));
    end;

    [Test]
    procedure DuplicateCompanySpendLimitForSamePeriodIsNotAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
    begin
        // [SCENARIO 617064] A second company spend limit for the same payment method, period type and period cannot be inserted.
        Initialize();

        // [GIVEN] A monthly company spend limit "L1" for the current month.
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::Company, '', '', 1000);

        // [WHEN] Another monthly company spend limit for the same month is inserted.
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::Company, '', '', 500);
        asserterror ExpenseSpendLimit[2].Insert(true);

        // [THEN] An error referring to "L1" is raised.
        Assert.ExpectedError(StrSubstNo(OverlappingSpendLimitErr, ExpenseSpendLimit[1]."No.", ExpenseSpendLimit[1]."Start Date", ExpenseSpendLimit[1]."End Date"));
    end;

    [Test]
    procedure ModifyingSpendLimitIntoOverlappingPeriodIsNotAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] An existing spend limit cannot be moved into the period of another spend limit for the same scope.
        Initialize();

        // [GIVEN] Monthly user spend limits "L1" for the current month and "L2" for the next month.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        ExpenseSpendLimit[2].Validate("Start Date", CalcDate('<CM+1D>', WorkDate()));
        ExpenseSpendLimit[2].Insert(true);

        // [WHEN] "L2" is moved to the current month.
        ExpenseSpendLimit[2].Validate("Start Date", WorkDate());
        asserterror ExpenseSpendLimit[2].Modify(true);

        // [THEN] An error referring to "L1" is raised.
        Assert.ExpectedError(StrSubstNo(OverlappingSpendLimitErr, ExpenseSpendLimit[1]."No.", ExpenseSpendLimit[1]."Start Date", ExpenseSpendLimit[1]."End Date"));
    end;

    [Test]
    procedure ModifyingSpendLimitWithoutChangingPeriodIsAllowed()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A spend limit does not conflict with itself when it is modified.
        Initialize();

        // [GIVEN] A monthly user spend limit.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] Its amount is changed.
        ExpenseSpendLimit.Validate("Amount (LCY)", 2000);
        ExpenseSpendLimit.Modify(true);

        // [THEN] The change is saved.
        ExpenseSpendLimit.Get(ExpenseSpendLimit."No.");
        Assert.AreEqual(2000, ExpenseSpendLimit."Amount (LCY)", ExpenseSpendLimit.FieldCaption("Amount (LCY)"));
    end;

    [Test]
    procedure SpendLimitsForConsecutivePeriodsAreAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Spend limits for the same scope in consecutive, non-overlapping periods are allowed.
        Initialize();

        // [GIVEN] A monthly user spend limit for the current month.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] A monthly user spend limit for the next month is inserted.
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        ExpenseSpendLimit[2].Validate("Start Date", CalcDate('<CM+1D>', WorkDate()));
        ExpenseSpendLimit[2].Insert(true);

        // [THEN] Both spend limits exist.
        VerifySpendLimitCount(ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", 2);
    end;

    [Test]
    procedure OverlappingSpendLimitWithDifferentPeriodTypeIsNotAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A spend limit with a different period type that overlaps an existing spend limit for the same user cannot be inserted.
        Initialize();

        // [GIVEN] A monthly user spend limit "L1" for the current month.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] A yearly user spend limit for the same user and the current year is inserted.
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser."No.", '', 1200);
        ExpenseSpendLimit[2].Validate("Period Type", ExpenseSpendLimit[2]."Period Type"::Year);
        asserterror ExpenseSpendLimit[2].Insert(true);

        // [THEN] An error referring to "L1" is raised.
        Assert.ExpectedError(StrSubstNo(OverlappingSpendLimitErr, ExpenseSpendLimit[1]."No.", ExpenseSpendLimit[1]."Start Date", ExpenseSpendLimit[1]."End Date"));
    end;

    [Test]
    procedure OverlappingSpendLimitWithDifferentPaymentMethodIsNotAllowed()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A spend limit with a different payment method that overlaps an existing spend limit for the same user cannot be inserted.
        Initialize();

        // [GIVEN] A monthly user spend limit "L1" for all payment methods for the current month.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, "Expense Reimbursement Type"::"Credit Card");
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] A monthly user spend limit for a specific payment method is inserted for the same user and month.
        InitSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser."No.", ExpensePaymentMethod.Code, 300);
        asserterror ExpenseSpendLimit[2].Insert(true);

        // [THEN] An error referring to "L1" is raised.
        Assert.ExpectedError(StrSubstNo(OverlappingSpendLimitErr, ExpenseSpendLimit[1]."No.", ExpenseSpendLimit[1]."Start Date", ExpenseSpendLimit[1]."End Date"));
    end;

    [Test]
    procedure SpendLimitsForDifferentUsersInSamePeriodAreAllowed()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 617064] Spend limits for different Expense Users in the same period are allowed.
        Initialize();

        // [GIVEN] Expense Users "U1" and "U2".
        MockExpenseUser(ExpenseUser[1], '');
        MockExpenseUser(ExpenseUser[2], '');

        // [WHEN] A monthly spend limit for the current month is inserted for each user.
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser[1]."No.", '', 1000);
        CreateSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser[2]."No.", '', 1000);

        // [THEN] Each user has one spend limit.
        VerifySpendLimitCount(ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser[1]."No.", 1);
        VerifySpendLimitCount(ExpenseSpendLimit[2]."Spend Limit Type"::User, ExpenseUser[2]."No.", 1);
    end;

    // =========================================================================
    // FlowFields on Expense User and Expense Team
    // =========================================================================

    [Test]
    procedure SpendingLimitPerUserReflectsUserSpendLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Spending Limit Per User shows whether a user spend limit exists for the Expense User.
        Initialize();

        // [GIVEN] An Expense User without a spend limit.
        MockExpenseUser(ExpenseUser, '');
        ExpenseUser.CalcFields("Spending Limit Per User");
        Assert.IsFalse(ExpenseUser."Spending Limit Per User", ExpenseUser.FieldCaption("Spending Limit Per User"));

        // [WHEN] A user spend limit is created for the Expense User.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [THEN] Spending Limit Per User is true.
        ExpenseUser.CalcFields("Spending Limit Per User");
        Assert.IsTrue(ExpenseUser."Spending Limit Per User", ExpenseUser.FieldCaption("Spending Limit Per User"));
    end;

    [Test]
    procedure SpendingLimitPerTeamReflectsTeamSpendLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
    begin
        // [SCENARIO 617064] Spending Limit Per Team shows whether a team spend limit exists for the Expense Team.
        Initialize();

        // [GIVEN] An Expense Team without a spend limit.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        ExpenseTeam.CalcFields("Spending Limit Per Team");
        Assert.IsFalse(ExpenseTeam."Spending Limit Per Team", ExpenseTeam.FieldCaption("Spending Limit Per Team"));

        // [WHEN] A team spend limit is created for the Expense Team.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 1000);

        // [THEN] Spending Limit Per Team is true.
        ExpenseTeam.CalcFields("Spending Limit Per Team");
        Assert.IsTrue(ExpenseTeam."Spending Limit Per Team", ExpenseTeam.FieldCaption("Spending Limit Per Team"));
    end;

    // =========================================================================
    // Expense User spend limit information
    // =========================================================================

    [Test]
    procedure UserSpendLimitInfoIsBlankWithoutSpendLimit()
    var
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Spend limit information is blank when no spend limit applies to the Expense User.
        Initialize();

        // [GIVEN] An Expense User with spending but without any spend limit.
        MockExpenseUser(ExpenseUser, '');
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');

        // [WHEN] / [THEN] Spend limit information is blank.
        VerifyUserSpendLimitInfo(ExpenseUser, 0, 0, 0, '');
    end;

    [Test]
    procedure UserSpendLimitInfoSumsOpenReportedAndPostedSpending()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Current spending sums open expenses, expense report lines and posted (not canceled) expense report lines within the period.
        Initialize();

        // [GIVEN] An Expense User with a monthly spend limit of 1000.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [GIVEN] An open expense of 100, an expense report line of 200 and a posted expense report line of 300 in the period.
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');
        MockExpenseReportLine(ExpenseUser."No.", WorkDate(), '', 200);
        MockPostedExpenseReportLine(ExpenseUser."No.", WorkDate(), '', 300, false);

        // [GIVEN] Expenses that must be ignored: already on an expense report, already posted, canceled posted line, and outside of the period.
        MockExpense(ExpenseUser."No.", WorkDate(), '', 5000, LibraryUtility.GenerateGUID(), '');
        MockExpense(ExpenseUser."No.", WorkDate(), '', 5000, '', LibraryUtility.GenerateGUID());
        MockPostedExpenseReportLine(ExpenseUser."No.", WorkDate(), '', 5000, true);
        MockExpense(ExpenseUser."No.", ExpenseSpendLimit."Start Date" - 1, '', 5000, '', '');
        MockExpenseReportLine(ExpenseUser."No.", ExpenseSpendLimit."End Date" + 1, '', 5000);

        // [WHEN] / [THEN] Current spending is 600 and 400 is available to use.
        VerifyUserSpendLimitInfo(ExpenseUser, 1000, 600, 400, '');
    end;

    [Test]
    procedure UserSpendLimitInfoFiltersByPaymentMethod()
    var
        ExpensePaymentMethod: array[2] of Record "Expense Payment Method";
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A spend limit for a payment method only counts spending with that payment method.
        Initialize();

        // [GIVEN] Two expense payment methods "PM1" and "PM2".
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod[1], "Expense Reimbursement Type"::"Employee Paid");
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod[2], "Expense Reimbursement Type"::"Credit Card");

        // [GIVEN] An Expense User with a spend limit of 1000 for "PM1".
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", ExpensePaymentMethod[1].Code, 1000);

        // [GIVEN] Expenses of 100 with "PM1" and 200 with "PM2".
        MockExpense(ExpenseUser."No.", WorkDate(), ExpensePaymentMethod[1].Code, 100, '', '');
        MockExpense(ExpenseUser."No.", WorkDate(), ExpensePaymentMethod[2].Code, 200, '', '');

        // [WHEN] / [THEN] Only the "PM1" spending is counted and the payment method is "PM1".
        VerifyUserSpendLimitInfo(ExpenseUser, 1000, 100, 900, ExpensePaymentMethod[1].Code);
    end;

    [Test]
    procedure UserSpendLimitInfoAvailableToUseIsZeroWhenLimitExceeded()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Available To Use is zero (not negative) when spending exceeds the limit.
        Initialize();

        // [GIVEN] An Expense User with a spend limit of 100 and spending of 150.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 100);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 150, '', '');

        // [WHEN] / [THEN] Current spending is 150 and Available To Use is 0.
        VerifyUserSpendLimitInfo(ExpenseUser, 100, 150, 0, '');
    end;

    [Test]
    procedure UserSpendLimitInfoIgnoresInactiveSpendLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A spend limit for a period that does not include the work date is ignored.
        Initialize();

        // [GIVEN] An Expense User with a spend limit for the previous month.
        MockExpenseUser(ExpenseUser, '');
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        ExpenseSpendLimit.Validate("Start Date", CalcDate('<-CM-1D>', WorkDate()));
        ExpenseSpendLimit.Insert(true);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');

        // [WHEN] / [THEN] Spend limit information is blank.
        VerifyUserSpendLimitInfo(ExpenseUser, 0, 0, 0, '');
    end;

    [Test]
    procedure UserSpendLimitInfoUsesUserLimitBeforeTeamAndCompanyLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 617064] When the Expense User has an active user limit, it is used even if the team or company limit is tighter.
        Initialize();

        // [GIVEN] Expense Team "T" with Expense Users "U1" and "U2".
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser[1], ExpenseTeam.Code);
        MockExpenseUser(ExpenseUser[2], ExpenseTeam.Code);

        // [GIVEN] User limit of 1000 for "U1", team limit of 500 for "T" and company limit of 1.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser[1]."No.", '', 1000);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 500);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1);

        // [GIVEN] "U1" spent 100 and "U2" spent 300.
        MockExpense(ExpenseUser[1]."No.", WorkDate(), '', 100, '', '');
        MockExpense(ExpenseUser[2]."No.", WorkDate(), '', 300, '', '');

        // [WHEN] / [THEN] For "U1" the user limit is shown with only the spending of "U1": limit 1000, spending 100, available 900.
        VerifyUserSpendLimitInfo(ExpenseUser[1], 1000, 100, 900, '');
    end;

    [Test]
    procedure UserSpendLimitInfoUsesTeamLimitWhenNoUserLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 617064] When the Expense User has no user limit, the team limit is used before the company limit.
        Initialize();

        // [GIVEN] Expense Team "T" with Expense Users "U1" and "U2", where "U1" has no user limit.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser[1], ExpenseTeam.Code);
        MockExpenseUser(ExpenseUser[2], ExpenseTeam.Code);

        // [GIVEN] Team limit of 500 for "T" and company limit of 1,000,000,000.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 500);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1000000000);

        // [GIVEN] "U1" spent 100 and "U2" spent 300.
        MockExpense(ExpenseUser[1]."No.", WorkDate(), '', 100, '', '');
        MockExpense(ExpenseUser[2]."No.", WorkDate(), '', 300, '', '');

        // [WHEN] / [THEN] For "U1" the team limit is shown with the team spending: limit 500, spending 400, available 100.
        VerifyUserSpendLimitInfo(ExpenseUser[1], 500, 400, 100, '');
    end;

    [Test]
    procedure UserSpendLimitInfoUsesTeamLimitWhenUserLimitIsNotActive()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] A user limit that is not active on the work date is skipped and the team limit is used.
        Initialize();

        // [GIVEN] Expense User "U" in Expense Team "T" with a user limit for the next month only.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, ExpenseTeam.Code);
        InitSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 200);
        ExpenseSpendLimit.Validate("Start Date", CalcDate('<CM+1D>', WorkDate()));
        ExpenseSpendLimit.Insert(true);

        // [GIVEN] Team limit of 5000 for "T" for the current month and "U" spent 50.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 5000);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 50, '', '');

        // [WHEN] / [THEN] The team limit is shown: limit 5000, spending 50, available 4950.
        VerifyUserSpendLimitInfo(ExpenseUser, 5000, 50, 4950, '');
    end;

    [Test]
    procedure UserSpendLimitInfoUsesCompanyLimitWhenNoUserOrTeamLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] When neither the Expense User nor its team has a limit, the company limit is used.
        Initialize();

        // [GIVEN] Expense User "U" in Expense Team "T", neither of which has a spend limit, and spending of 100.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, ExpenseTeam.Code);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');

        // [GIVEN] A company limit of 1, which is already exceeded by the company spending.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1);

        // [WHEN] / [THEN] The company limit is shown with the company spending and nothing available to use.
        VerifyUserSpendLimitInfo(ExpenseUser, 1, GetCompanySpendingLCY(ExpenseSpendLimit), 0, '');
    end;

    // =========================================================================
    // Expense Team spend limit information
    // =========================================================================

    [Test]
    procedure TeamSpendLimitInfoSumsSpendingOfTeamMembers()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: array[3] of Record "Expense User";
    begin
        // [SCENARIO 617064] Team current spending sums the spending of all team members only.
        Initialize();

        // [GIVEN] Expense Team "T" with members "U1" and "U2", and "U3" who is not a member.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser[1], ExpenseTeam.Code);
        MockExpenseUser(ExpenseUser[2], ExpenseTeam.Code);
        MockExpenseUser(ExpenseUser[3], '');

        // [GIVEN] Team limit of 1000 for "T".
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 1000);

        // [GIVEN] "U1" spent 100, "U2" spent 250 and "U3" spent 5000.
        MockExpense(ExpenseUser[1]."No.", WorkDate(), '', 100, '', '');
        MockExpenseReportLine(ExpenseUser[2]."No.", WorkDate(), '', 250);
        MockExpense(ExpenseUser[3]."No.", WorkDate(), '', 5000, '', '');

        // [WHEN] / [THEN] Team spending is 350 and 650 is available to use.
        VerifyTeamSpendLimitInfo(ExpenseTeam, 1000, 350, 650, '');
    end;

    [Test]
    procedure TeamSpendLimitInfoIsBlankWithoutSpendLimit()
    var
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Spend limit information is blank when no spend limit applies to the Expense Team.
        Initialize();

        // [GIVEN] An Expense Team with spending but without any spend limit.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, ExpenseTeam.Code);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');

        // [WHEN] / [THEN] Spend limit information is blank.
        VerifyTeamSpendLimitInfo(ExpenseTeam, 0, 0, 0, '');
    end;

    [Test]
    procedure TeamSpendLimitInfoUsesTeamLimitBeforeCompanyLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] When the Expense Team has an active team limit, it is used even if the company limit is tighter.
        Initialize();

        // [GIVEN] Expense Team "T" with a member who spent 400.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, ExpenseTeam.Code);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 400, '', '');

        // [GIVEN] Team limit of 1000 for "T" and company limit of 1.
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 1000);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1);

        // [WHEN] / [THEN] The team limit is shown: limit 1000, spending 400, available 600.
        VerifyTeamSpendLimitInfo(ExpenseTeam, 1000, 400, 600, '');
    end;

    [Test]
    procedure TeamSpendLimitInfoUsesCompanyLimitWithoutTeamLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        AvailableSpendLimitLCY: Decimal;
        CompanySpendingBeforeLCY: Decimal;
        CompanySpendingAfterLCY: Decimal;
        AvailableToUseLCY: Decimal;
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO 617064] Without a team limit the company limit is shown, and company spending includes all users.
        Initialize();

        // [GIVEN] An Expense Team without a team limit and a company limit of 1,000,000,000.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Company, '', '', 1000000000);
        GetTeamSpendLimitInfo(ExpenseTeam, AvailableSpendLimitLCY, CompanySpendingBeforeLCY, AvailableToUseLCY, PaymentMethodCode);

        // [WHEN] An Expense User who is not a member of the team spends 100.
        MockExpense(ExpenseUser."No.", WorkDate(), '', 100, '', '');

        // [THEN] The company limit is shown and company spending increased by 100.
        GetTeamSpendLimitInfo(ExpenseTeam, AvailableSpendLimitLCY, CompanySpendingAfterLCY, AvailableToUseLCY, PaymentMethodCode);
        Assert.AreEqual(1000000000, AvailableSpendLimitLCY, 'Available Spend Limit (LCY)');
        Assert.AreEqual(CompanySpendingBeforeLCY + 100, CompanySpendingAfterLCY, 'Current Spending (LCY)');
        Assert.AreEqual(1000000000 - CompanySpendingAfterLCY, AvailableToUseLCY, 'Available To Use (LCY)');
    end;

    // =========================================================================
    // Deletion
    // =========================================================================

    [Test]
    procedure DeletingExpenseUserDeletesUserSpendLimits()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 617064] Deleting an Expense User deletes the user's spend limits.
        Initialize();

        // [GIVEN] An Expense User with a user spend limit.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);

        // [WHEN] The Expense User is deleted.
        ExpenseUser.Delete(true);

        // [THEN] The user spend limit is deleted.
        ExpenseSpendLimit.SetRange("Spend Limit Type", ExpenseSpendLimit."Spend Limit Type"::User);
        ExpenseSpendLimit.SetRange("Limit For", ExpenseUser."No.");
        Assert.RecordIsEmpty(ExpenseSpendLimit);
    end;

    [Test]
    procedure DeletingExpenseTeamDeletesTeamSpendLimits()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
    begin
        // [SCENARIO 617064] Deleting an Expense Team deletes the team's spend limits.
        Initialize();

        // [GIVEN] An Expense Team with a team spend limit.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 1000);

        // [WHEN] The Expense Team is deleted.
        ExpenseTeam.Delete(true);

        // [THEN] The team spend limit is deleted.
        ExpenseSpendLimit.SetRange("Spend Limit Type", ExpenseSpendLimit."Spend Limit Type"::Team);
        ExpenseSpendLimit.SetRange("Limit For", ExpenseTeam.Code);
        Assert.RecordIsEmpty(ExpenseSpendLimit);
    end;

    // =========================================================================
    // Pages
    // =========================================================================

    [Test]
    procedure ExpenseUserPageShowsSpendLimitInformation()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
        ExpenseUserPage: TestPage "Expense User";
    begin
        // [SCENARIO 617064] The Expense User page shows the spend limit information.
        Initialize();

        // [GIVEN] An Expense User with a user limit of 1000 and spending of 300.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 300, '', '');

        // [WHEN] The Expense User page is opened.
        ExpenseUserPage.OpenView();
        ExpenseUserPage.GoToRecord(ExpenseUser);

        // [THEN] The spend limit information is shown.
        Assert.IsTrue(ExpenseUserPage."Spending Limit Per User".AsBoolean(), ExpenseUser.FieldCaption("Spending Limit Per User"));
        ExpenseUserPage."Available Spend Limit (LCY)".AssertEquals(1000);
        ExpenseUserPage."Current Spending (LCY)".AssertEquals(300);
        ExpenseUserPage."Available To Use (LCY)".AssertEquals(700);
        ExpenseUserPage.Close();
    end;

    [Test]
    procedure ExpenseTeamCardShowsSpendLimitInformation()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        ExpenseTeam: Record "Expense Team";
        ExpenseUser: Record "Expense User";
        ExpenseTeamCard: TestPage "Expense Team Card";
    begin
        // [SCENARIO 617064] The Expense Team Card shows the spend limit information.
        Initialize();

        // [GIVEN] An Expense Team with a team limit of 1000 and a member who spent 400.
        LibraryExpense.CreateExpenseTeam(ExpenseTeam);
        MockExpenseUser(ExpenseUser, ExpenseTeam.Code);
        CreateSpendLimit(ExpenseSpendLimit, ExpenseSpendLimit."Spend Limit Type"::Team, ExpenseTeam.Code, '', 1000);
        MockExpense(ExpenseUser."No.", WorkDate(), '', 400, '', '');

        // [WHEN] The Expense Team Card is opened.
        ExpenseTeamCard.OpenView();
        ExpenseTeamCard.GoToRecord(ExpenseTeam);

        // [THEN] The spend limit information is shown.
        Assert.IsTrue(ExpenseTeamCard."Spending Limit Per Team".AsBoolean(), ExpenseTeam.FieldCaption("Spending Limit Per Team"));
        ExpenseTeamCard."Available Spend Limit (LCY)".AssertEquals(1000);
        ExpenseTeamCard."Current Spending (LCY)".AssertEquals(400);
        ExpenseTeamCard."Available To Use (LCY)".AssertEquals(600);
        ExpenseTeamCard.Close();
    end;

    [Test]
    procedure SpendLimitsPageLimitForIsEditableOnlyForUserAndTeam()
    var
        ExpenseSpendLimit: array[2] of Record "Expense Spend Limit";
        ExpenseUser: Record "Expense User";
        ExpenseSpendLimits: TestPage "Expense Spend Limits";
    begin
        // [SCENARIO 617064] Limit For is editable for user and team limits, and not editable for company limits.
        Initialize();

        // [GIVEN] A user spend limit and a company spend limit.
        MockExpenseUser(ExpenseUser, '');
        CreateSpendLimit(ExpenseSpendLimit[1], ExpenseSpendLimit[1]."Spend Limit Type"::User, ExpenseUser."No.", '', 1000);
        CreateSpendLimit(ExpenseSpendLimit[2], ExpenseSpendLimit[2]."Spend Limit Type"::Company, '', '', 1000);

        // [WHEN] The Expense Spend Limits page is opened.
        ExpenseSpendLimits.OpenEdit();

        // [THEN] Limit For is editable for the user limit and not editable for the company limit.
        ExpenseSpendLimits.GoToRecord(ExpenseSpendLimit[1]);
        Assert.IsTrue(ExpenseSpendLimits."Limit For".Editable(), ExpenseSpendLimit[1].FieldCaption("Limit For"));
        ExpenseSpendLimits.GoToRecord(ExpenseSpendLimit[2]);
        Assert.IsFalse(ExpenseSpendLimits."Limit For".Editable(), ExpenseSpendLimit[2].FieldCaption("Limit For"));
        ExpenseSpendLimits.Close();
    end;

    // =========================================================================
    // Helpers
    // =========================================================================

    local procedure Initialize()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Spend Limit Test");
        ExpenseSpendLimit.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Spend Limit Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Spend Limit Test");
    end;

    local procedure InitSpendLimit(var ExpenseSpendLimit: Record "Expense Spend Limit"; SpendLimitType: Enum "Exp. Spend Limit Type"; LimitFor: Code[20]; PaymentMethodCode: Code[10]; AmountLCY: Decimal)
    begin
        ExpenseSpendLimit.Init();
        ExpenseSpendLimit."No." := 0;
        ExpenseSpendLimit.Validate("Spend Limit Type", SpendLimitType);
        if LimitFor <> '' then
            ExpenseSpendLimit.Validate("Limit For", LimitFor);
        ExpenseSpendLimit.Validate("Period Type", ExpenseSpendLimit."Period Type"::Month);
        ExpenseSpendLimit.Validate("Start Date", WorkDate());
        if PaymentMethodCode <> '' then
            ExpenseSpendLimit.Validate("Payment Method Code", PaymentMethodCode);
        if AmountLCY <> 0 then
            ExpenseSpendLimit.Validate("Amount (LCY)", AmountLCY);
    end;

    local procedure CreateSpendLimit(var ExpenseSpendLimit: Record "Expense Spend Limit"; SpendLimitType: Enum "Exp. Spend Limit Type"; LimitFor: Code[20]; PaymentMethodCode: Code[10]; AmountLCY: Decimal)
    begin
        InitSpendLimit(ExpenseSpendLimit, SpendLimitType, LimitFor, PaymentMethodCode, AmountLCY);
        ExpenseSpendLimit.Insert(true);
    end;

    local procedure MockExpenseUser(var ExpenseUser: Record "Expense User"; ExpenseTeamCode: Code[20])
    begin
        ExpenseUser.Init();
        ExpenseUser."No." := LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User");
        ExpenseUser."Employee No." := LibraryHumanResource.CreateEmployeeNo();
        ExpenseUser."Expense Team Code" := ExpenseTeamCode;
        ExpenseUser.Insert(false);
    end;

    local procedure MockExpense(ExpenseUserNo: Code[20]; ExpenseDate: Date; PaymentMethodCode: Code[10]; AmountLCY: Decimal; ExpenseReportNo: Code[20]; PostedExpenseReportNo: Code[20])
    var
        Expense: Record Expense;
    begin
        Expense.Init();
        Expense."No." := LibraryUtility.GenerateRandomCode(Expense.FieldNo("No."), Database::Expense);
        Expense.Insert(false);
        // Assign after insert: the OnAfterInsertEvent subscriber re-applies rules and recalculates amounts.
        Expense."Expense User No." := ExpenseUserNo;
        Expense."Expense Date" := ExpenseDate;
        Expense."Payment Method Code" := PaymentMethodCode;
        Expense."Amount (LCY)" := AmountLCY;
        Expense."Expense Report No." := ExpenseReportNo;
        Expense."Posted Expense Report No." := PostedExpenseReportNo;
        Expense.Modify(false);
    end;

    local procedure MockExpenseReportLine(ExpenseUserNo: Code[20]; ExpenseDate: Date; PaymentMethodCode: Code[10]; AmountLCY: Decimal)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Init();
        ExpenseReportLine."Document No." := LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo("Document No."), Database::"Expense Report Line");
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Expense User No." := ExpenseUserNo;
        ExpenseReportLine."Expense Date" := ExpenseDate;
        ExpenseReportLine."Payment Method Code" := PaymentMethodCode;
        ExpenseReportLine."Amount (LCY)" := AmountLCY;
        ExpenseReportLine.Insert(false);
    end;

    local procedure MockPostedExpenseReportLine(ExpenseUserNo: Code[20]; ExpenseDate: Date; PaymentMethodCode: Code[10]; AmountLCY: Decimal; IsCanceled: Boolean)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        PostedExpenseReportLine.Init();
        PostedExpenseReportLine."Document No." := LibraryUtility.GenerateRandomCode(PostedExpenseReportLine.FieldNo("Document No."), Database::"Posted Expense Report Line");
        PostedExpenseReportLine."Line No." := 10000;
        PostedExpenseReportLine."Expense User No." := ExpenseUserNo;
        PostedExpenseReportLine."Expense Date" := ExpenseDate;
        PostedExpenseReportLine."Payment Method Code" := PaymentMethodCode;
        PostedExpenseReportLine."Amount (LCY)" := AmountLCY;
        PostedExpenseReportLine."Is Canceled" := IsCanceled;
        PostedExpenseReportLine.Insert(false);
    end;

    local procedure MockAccountingPeriod(StartingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.Get(StartingDate) then
            exit;

        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := StartingDate;
        AccountingPeriod.Insert(false);
    end;

    local procedure GetCompanySpendingLCY(ExpenseSpendLimit: Record "Expense Spend Limit"): Decimal
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        Expense.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        Expense.SetRange("Expense Report No.", '');
        Expense.SetRange("Posted Expense Report No.", '');
        Expense.CalcSums("Amount (LCY)");

        ExpenseReportLine.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        ExpenseReportLine.CalcSums("Amount (LCY)");

        PostedExpenseReportLine.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        PostedExpenseReportLine.CalcSums("Amount (LCY)");

        exit(Expense."Amount (LCY)" + ExpenseReportLine."Amount (LCY)" + PostedExpenseReportLine."Amount (LCY)");
    end;

    local procedure GetTeamSpendLimitInfo(ExpenseTeam: Record "Expense Team"; var AvailableSpendLimitLCY: Decimal; var CurrentSpendingLCY: Decimal; var AvailableToUseLCY: Decimal; var PaymentMethodCode: Code[10])
    var
        ExpenseSpendLimitMgt: Codeunit "Expense Spend Limit Mgt.";
    begin
        ExpenseSpendLimitMgt.GetExpenseTeamSpendLimitInfo(ExpenseTeam, AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode);
    end;

    local procedure VerifyUserSpendLimitInfo(ExpenseUser: Record "Expense User"; ExpectedAvailableSpendLimitLCY: Decimal; ExpectedCurrentSpendingLCY: Decimal; ExpectedAvailableToUseLCY: Decimal; ExpectedPaymentMethodCode: Code[10])
    var
        ExpenseSpendLimitMgt: Codeunit "Expense Spend Limit Mgt.";
        AvailableSpendLimitLCY: Decimal;
        CurrentSpendingLCY: Decimal;
        AvailableToUseLCY: Decimal;
        PaymentMethodCode: Code[10];
    begin
        ExpenseSpendLimitMgt.GetExpenseUserSpendLimitInfo(ExpenseUser, AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode);
        VerifySpendLimitInfo(
            AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode,
            ExpectedAvailableSpendLimitLCY, ExpectedCurrentSpendingLCY, ExpectedAvailableToUseLCY, ExpectedPaymentMethodCode);
    end;

    local procedure VerifyTeamSpendLimitInfo(ExpenseTeam: Record "Expense Team"; ExpectedAvailableSpendLimitLCY: Decimal; ExpectedCurrentSpendingLCY: Decimal; ExpectedAvailableToUseLCY: Decimal; ExpectedPaymentMethodCode: Code[10])
    var
        AvailableSpendLimitLCY: Decimal;
        CurrentSpendingLCY: Decimal;
        AvailableToUseLCY: Decimal;
        PaymentMethodCode: Code[10];
    begin
        GetTeamSpendLimitInfo(ExpenseTeam, AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode);
        VerifySpendLimitInfo(
            AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode,
            ExpectedAvailableSpendLimitLCY, ExpectedCurrentSpendingLCY, ExpectedAvailableToUseLCY, ExpectedPaymentMethodCode);
    end;

    local procedure VerifySpendLimitCount(SpendLimitType: Enum "Exp. Spend Limit Type"; LimitFor: Code[20]; ExpectedCount: Integer)
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        ExpenseSpendLimit.SetRange("Spend Limit Type", SpendLimitType);
        ExpenseSpendLimit.SetRange("Limit For", LimitFor);
        Assert.RecordCount(ExpenseSpendLimit, ExpectedCount);
    end;

    local procedure VerifySpendLimitInfo(AvailableSpendLimitLCY: Decimal; CurrentSpendingLCY: Decimal; AvailableToUseLCY: Decimal; PaymentMethodCode: Code[10]; ExpectedAvailableSpendLimitLCY: Decimal; ExpectedCurrentSpendingLCY: Decimal; ExpectedAvailableToUseLCY: Decimal; ExpectedPaymentMethodCode: Code[10])
    begin
        Assert.AreEqual(ExpectedAvailableSpendLimitLCY, AvailableSpendLimitLCY, 'Available Spend Limit (LCY)');
        Assert.AreEqual(ExpectedCurrentSpendingLCY, CurrentSpendingLCY, 'Current Spending (LCY)');
        Assert.AreEqual(ExpectedAvailableToUseLCY, AvailableToUseLCY, 'Available To Use (LCY)');
        Assert.AreEqual(ExpectedPaymentMethodCode, PaymentMethodCode, 'Spend Limit Payment Method');
    end;
}
