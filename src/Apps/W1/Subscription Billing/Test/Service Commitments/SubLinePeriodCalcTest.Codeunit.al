namespace Microsoft.SubscriptionBilling;

codeunit 139893 "Sub. Line Period Calc. Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    Access = Internal;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PeriodStretchedErr: Label 'Day/week period must not be aligned to the end of the month.', Locked = true;

    [Test]
    procedure DayRhythmAlignToEndOfMonthNotStretchedAtMonthEnd()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO 647093] A day rhythm must keep its fixed length even when the line starts at month-end and uses 'Align to End of Month'.
        Initialize();

        // [GIVEN] A subscription line starting on a month-end date (30.04.2026) with 'Align to End of Month'
        CreateSubscriptionLineForPeriodCalc(SubscriptionLine, DMY2Date(30, 4, 2026), SubscriptionLine."Period Calculation"::"Align to End of Month");

        // [WHEN] The end of the first 10-day period is calculated
        // [THEN] The period spans exactly 10 days (30.04 - 09.05) and is not stretched to the end of the month
        Assert.AreEqual(DMY2Date(9, 5, 2026), SubscriptionLine.CalculateNextToDate(EvaluateDateFormula('<10D>'), DMY2Date(30, 4, 2026)), PeriodStretchedErr);
    end;

    [Test]
    procedure WeekRhythmAlignToEndOfMonthNotStretchedAtMonthEnd()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO 647093] A week rhythm must keep its fixed length even when the line starts at month-end and uses 'Align to End of Month'.
        Initialize();

        // [GIVEN] A subscription line starting on a month-end date (30.04.2026) with 'Align to End of Month'
        CreateSubscriptionLineForPeriodCalc(SubscriptionLine, DMY2Date(30, 4, 2026), SubscriptionLine."Period Calculation"::"Align to End of Month");

        // [WHEN] The end of the first 2-week period is calculated
        // [THEN] The period spans exactly 14 days (30.04 - 13.05) and is not stretched to the end of the month
        Assert.AreEqual(DMY2Date(13, 5, 2026), SubscriptionLine.CalculateNextToDate(EvaluateDateFormula('<2W>'), DMY2Date(30, 4, 2026)), PeriodStretchedErr);
    end;

    [Test]
    procedure DayRhythmPeriodLengthIndependentOfMonthEndProximity()
    var
        SubscriptionLineAtMonthEnd: Record "Subscription Line";
        SubscriptionLineShifted: Record "Subscription Line";
        PeriodEndAtMonthEnd: Date;
        PeriodEndShifted: Date;
    begin
        // [SCENARIO 647093] Shifting the start date by a few days must not change the length of a day-rhythm period.
        Initialize();

        // [GIVEN] Two subscription lines with 'Align to End of Month', one starting at month-end (30.04) and one shifted 3 days earlier (27.04)
        CreateSubscriptionLineForPeriodCalc(SubscriptionLineAtMonthEnd, DMY2Date(30, 4, 2026), SubscriptionLineAtMonthEnd."Period Calculation"::"Align to End of Month");
        CreateSubscriptionLineForPeriodCalc(SubscriptionLineShifted, DMY2Date(27, 4, 2026), SubscriptionLineShifted."Period Calculation"::"Align to End of Month");

        // [WHEN] The first 10-day period is calculated for both lines
        PeriodEndAtMonthEnd := SubscriptionLineAtMonthEnd.CalculateNextToDate(EvaluateDateFormula('<10D>'), DMY2Date(30, 4, 2026));
        PeriodEndShifted := SubscriptionLineShifted.CalculateNextToDate(EvaluateDateFormula('<10D>'), DMY2Date(27, 4, 2026));

        // [THEN] Both periods cover the same number of days
        Assert.AreEqual(
            PeriodEndAtMonthEnd - DMY2Date(30, 4, 2026),
            PeriodEndShifted - DMY2Date(27, 4, 2026),
            PeriodStretchedErr);
    end;

    [Test]
    procedure DayRhythmAlignToEndOfMonthLeapYearFebruary()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO 647093] A day rhythm starting on the 29th of February (leap year) with 'Align to End of Month' keeps its fixed length.
        Initialize();

        // [GIVEN] A subscription line starting on 29.02.2028 (leap year) with 'Align to End of Month'
        CreateSubscriptionLineForPeriodCalc(SubscriptionLine, DMY2Date(29, 2, 2028), SubscriptionLine."Period Calculation"::"Align to End of Month");

        // [WHEN] The end of the first 10-day period is calculated
        // [THEN] The period spans exactly 10 days (29.02 - 09.03) and is not stretched to the end of the month
        Assert.AreEqual(DMY2Date(9, 3, 2028), SubscriptionLine.CalculateNextToDate(EvaluateDateFormula('<10D>'), DMY2Date(29, 2, 2028)), PeriodStretchedErr);
    end;

    [Test]
    procedure MonthRhythmStillAlignsToEndOfMonth()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        // [SCENARIO 647093] Month rhythms must keep aligning to the end of the month (regression guard for the day/week fix).
        Initialize();

        // [GIVEN] A subscription line starting on a month-end date (28.02.2026) with 'Align to End of Month'
        CreateSubscriptionLineForPeriodCalc(SubscriptionLine, DMY2Date(28, 2, 2026), SubscriptionLine."Period Calculation"::"Align to End of Month");

        // [WHEN] The end of the first month period is calculated
        // [THEN] The period is aligned to the end of the month (30.03.2026), not the plain formula result (27.03.2026)
        Assert.AreEqual(DMY2Date(30, 3, 2026), SubscriptionLine.CalculateNextToDate(EvaluateDateFormula('<1M>'), DMY2Date(28, 2, 2026)), 'Month rhythm must still align to the end of the month.');
    end;

    [Test]
    procedure UnitPriceEqualForShiftedMonthEndStartDates()
    var
        SubscriptionLineAtMonthEnd: Record "Subscription Line";
        SubscriptionLineShifted: Record "Subscription Line";
        UnitPriceAtMonthEnd: Decimal;
        UnitPriceShifted: Decimal;
    begin
        // [SCENARIO 647093] The billed amount for a full day-rhythm period must not depend on the start date's proximity to month-end.
        Initialize();

        // [GIVEN] A subscription line with a 10D rhythm and base period, price 1050, starting at month-end (30.04.2026)
        CreateSubscriptionLineForProration(SubscriptionLineAtMonthEnd, DMY2Date(30, 4, 2026), '<10D>', '<10D>', 1050);
        // [GIVEN] An identical line shifted 3 days earlier (27.04.2026)
        CreateSubscriptionLineForProration(SubscriptionLineShifted, DMY2Date(27, 4, 2026), '<10D>', '<10D>', 1050);

        // [WHEN] The unit price for the first full 10-day period is calculated for both lines
        UnitPriceAtMonthEnd := SubscriptionLineAtMonthEnd.UnitPriceForPeriod(DMY2Date(30, 4, 2026), DMY2Date(9, 5, 2026));
        UnitPriceShifted := SubscriptionLineShifted.UnitPriceForPeriod(DMY2Date(27, 4, 2026), DMY2Date(6, 5, 2026));

        // [THEN] Both lines are billed the full period price and the amounts are identical
        Assert.AreEqual(1050, UnitPriceAtMonthEnd, 'Full period at month-end must be billed the complete period price.');
        Assert.AreEqual(UnitPriceAtMonthEnd, UnitPriceShifted, 'Shifting the start date must not change the billed amount.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sub. Line Period Calc. Test");
    end;

    local procedure CreateSubscriptionLineForPeriodCalc(var SubscriptionLine: Record "Subscription Line"; StartDate: Date; PeriodCalculation: Enum "Period Calculation")
    begin
        SubscriptionLine.Init();
        SubscriptionLine."Entry No." := 0;
        SubscriptionLine."Subscription Line Start Date" := StartDate;
        SubscriptionLine."Period Calculation" := PeriodCalculation;
    end;

    local procedure CreateSubscriptionLineForProration(var SubscriptionLine: Record "Subscription Line"; StartDate: Date; BillingBasePeriodText: Text; BillingRhythmText: Text; Price: Decimal)
    begin
        CreateSubscriptionLineForPeriodCalc(SubscriptionLine, StartDate, SubscriptionLine."Period Calculation"::"Align to End of Month");
        SubscriptionLine."Billing Base Period" := EvaluateDateFormula(BillingBasePeriodText);
        SubscriptionLine."Billing Rhythm" := EvaluateDateFormula(BillingRhythmText);
        SubscriptionLine.Price := Price;
    end;

    local procedure EvaluateDateFormula(DateFormulaText: Text) DateFormulaResult: DateFormula
    begin
        Evaluate(DateFormulaResult, DateFormulaText);
    end;
}
