codeunit 134996 "UT Period Form Mgt"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Period] [Date Filter] [UT]
    end;

    var
        PeriodPageManagement: Codeunit PeriodPageManagement;
        Assert: Codeunit Assert;
        IncorrectDateFilterErr: Label 'Incorrect date filter.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_EmptyDateFilter()
    begin
        Assert.AreEqual('', PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Day, ''), IncorrectDateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_Day()
    var
        DateFilter: Text;
    begin
        DateFilter := GetRandomDateFilter();
        VerifyDateFilter(DateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Day, DateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_Week()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeRandomDateFilterByPeriod(ActualDateFilter, ExpectedDateFilter, PeriodType::Week);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Week, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_Month()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeRandomDateFilterByPeriod(ActualDateFilter, ExpectedDateFilter, PeriodType::Month);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Month, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_FullMonth()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        // Verify that full period gives the same full period result filter
        // Test for month only due to other period types use the same algoritm
        MakeRandomDateFilterByPeriod(ActualDateFilter, ExpectedDateFilter, PeriodType::Month);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Month, ExpectedDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_FewMonth()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeRandomDateFilterFewMonth(ActualDateFilter, ExpectedDateFilter);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Month, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_MonthOneDayFilter()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeOneDayDateFilter(ActualDateFilter, ExpectedDateFilter);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Month, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_Quarter()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeRandomDateFilterByPeriod(ActualDateFilter, ExpectedDateFilter, PeriodType::Quarter);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Quarter, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_Year()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeRandomDateFilterByPeriod(ActualDateFilter, ExpectedDateFilter, PeriodType::Year);
        VerifyDateFilter(ExpectedDateFilter, PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::Year, ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_AccountPeriod()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeAccountingPeriodRandomFilter(ActualDateFilter, ExpectedDateFilter, 1);
        VerifyDateFilter(ExpectedDateFilter,
          PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::"Accounting Period", ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullPeriodDateFilter_FewAccountPeriods()
    var
        ActualDateFilter: Text;
        ExpectedDateFilter: Text;
    begin
        MakeAccountingPeriodRandomFilter(ActualDateFilter, ExpectedDateFilter, LibraryRandom.RandIntInRange(5, 10));
        VerifyDateFilter(ExpectedDateFilter,
          PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type"::"Accounting Period", ActualDateFilter));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriod_Month()
    begin
        Assert.AreEqual(DMY2Date(1, 2, 2018), PeriodPageManagement.MoveDateByPeriod(DMY2Date(1, 1, 2018), PeriodType::Month, 1),
          'Expected to move date by 1 Month');
        Assert.AreEqual(DMY2Date(1, 12, 2017), PeriodPageManagement.MoveDateByPeriod(DMY2Date(1, 1, 2018), PeriodType::Month, -1),
          'Expected to move date by -1 Month');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriod_Quarter()
    begin
        Assert.AreEqual(DMY2Date(10, 12, 2018), PeriodPageManagement.MoveDateByPeriod(DMY2Date(10, 6, 2018), PeriodType::Quarter, 2),
          'Expected to move date by 2 Quarters');
        Assert.AreEqual(DMY2Date(5, 4, 2017), PeriodPageManagement.MoveDateByPeriod(DMY2Date(5, 1, 2018), PeriodType::Quarter, -3),
          'Expected to move date by -3 Quarters');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriod_Year()
    begin
        Assert.AreEqual(DMY2Date(31, 7, 2023), PeriodPageManagement.MoveDateByPeriod(DMY2Date(31, 7, 2018), PeriodType::Year, 5),
          'Expected to move date by 5 Years');
        Assert.AreEqual(DMY2Date(1, 1, 2016), PeriodPageManagement.MoveDateByPeriod(DMY2Date(1, 1, 2018), PeriodType::Year, -2),
          'Expected to move date by -2 Years');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriodToEndOfPeriod_Month()
    begin
        Assert.AreEqual(
          DMY2Date(28, 2, 2018), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(1, 1, 2018), PeriodType::Month, 1),
          'Expected to move date by 1 Month and go to end of period');
        Assert.AreEqual(
          DMY2Date(31, 12, 2017), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(1, 1, 2018), PeriodType::Month, -1),
          'Expected to move date by -1 Month and go to end of period');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriodToEndOfPeriod_Quarter()
    begin
        Assert.AreEqual(
          DMY2Date(9, 3, 2019), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(10, 6, 2018), PeriodType::Quarter, 2),
          'Expected to move date by 2 Quarters and go to end of period');
        Assert.AreEqual(
          DMY2Date(4, 7, 2017), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(5, 1, 2018), PeriodType::Quarter, -3),
          'Expected to move date by -3 Quarters and go to end of period');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveDateByPeriodToEndOfPeriod_Year()
    begin
        Assert.AreEqual(
          DMY2Date(30, 7, 2024), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(31, 7, 2018), PeriodType::Year, 5),
          'Expected to move date by 5 Years and go to end of period');
        Assert.AreEqual(
          DMY2Date(31, 12, 2016), PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(DMY2Date(1, 1, 2018), PeriodType::Year, -2),
          'Expected to move date by -2 Years and go to end of period');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindDateLargerLastAccountingPeriodStartingDate()
    var
        AccountingPeriod: Record "Accounting Period";
        Calendar: Record Date;
    begin
        // [SCENARIO 312912] Function FindDate returns Calendar."Period End" = 31.12.9999 in case Calendar."Period Start" is equal to Starting Date of the last Accounting Period.

        // [GIVEN] Set Calendar."Period Start" = AccountingPeriod."Starting Date" of the last Accounting Period.
        AccountingPeriod.FindLast();
        Calendar."Period Start" := AccountingPeriod."Starting Date";

        // [WHEN] Run FindDate function on this Calendar record with SearchString ">=" and Period Type "Accounting Period".
        PeriodPageManagement.FindDate('>=', Calendar, "Analysis Period Type"::"Accounting Period");

        // [THEN] Calendar."Period End" is equal to 31.12.9999.
        Calendar.TestField("Period End", DMY2Date(31, 12, 9999));
    end;

    local procedure GetRandomDateFilter(): Text
    begin
        exit(GetDateFilter(WorkDate(), WorkDate() + LibraryRandom.RandIntInRange(5, 10)));
    end;

    local procedure GetDateFilter(StartDate: Date; EndDate: Date): Text
    var
        Period: Record Date;
    begin
        Period.SetRange("Period Start", StartDate, EndDate);
        exit(Period.GetFilter("Period Start"));
    end;

    local procedure MakeRandomDateFilterByPeriod(var ActualDateFilter: Text; var ExpectedDateFilter: Text; PerType: Option)
    var
        ActualStartDate: Date;
        ActualEndDate: Date;
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
    begin
        case PerType of
            PeriodType::Week:
                begin
                    ActualStartDate := CalcDate('<-CW+1D>', WorkDate());
                    ActualEndDate := CalcDate('<CW-1D>', WorkDate());
                    ExpectedStartDate := CalcDate('<-CW>', WorkDate());
                    ExpectedEndDate := CalcDate('<CW>', WorkDate());
                end;
            PeriodType::Month:
                begin
                    ActualStartDate := CalcDate('<-CM+1D>', WorkDate());
                    ActualEndDate := CalcDate('<CM-1D>', WorkDate());
                    ExpectedStartDate := CalcDate('<-CM>', WorkDate());
                    ExpectedEndDate := CalcDate('<CM>', WorkDate());
                end;
            PeriodType::Quarter:
                begin
                    ActualStartDate := CalcDate('<-CQ+1D>', WorkDate());
                    ActualEndDate := CalcDate('<CQ-1D>', WorkDate());
                    ExpectedStartDate := CalcDate('<-CQ>', WorkDate());
                    ExpectedEndDate := CalcDate('<CQ>', WorkDate());
                end;
            PeriodType::Year:
                begin
                    ActualStartDate := CalcDate('<-CY+1D>', WorkDate());
                    ActualEndDate := CalcDate('<CY-1D>', WorkDate());
                    ExpectedStartDate := CalcDate('<-CY>', WorkDate());
                    ExpectedEndDate := CalcDate('<CY>', WorkDate());
                end;
        end;
        MakeActualAndExpectedDateFilters(ActualStartDate, ActualEndDate, ExpectedStartDate, ExpectedEndDate,
          ActualDateFilter, ExpectedDateFilter)
    end;

    local procedure MakeRandomDateFilterFewMonth(var ActualDateFilter: Text; var ExpectedDateFilter: Text)
    var
        ActualStartDate: Date;
        ActualEndDate: Date;
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
    begin
        ActualStartDate := CalcDate('<-CM+1D>', WorkDate());
        ActualEndDate := CalcDate(StrSubstNo('<%1M-1D>', LibraryRandom.RandInt(10)), WorkDate());
        ExpectedStartDate := CalcDate('<-CM>', ActualStartDate);
        ExpectedEndDate := CalcDate('<CM>', ActualEndDate);

        MakeActualAndExpectedDateFilters(ActualStartDate, ActualEndDate, ExpectedStartDate, ExpectedEndDate,
          ActualDateFilter, ExpectedDateFilter)
    end;

    local procedure MakeOneDayDateFilter(var ActualDateFilter: Text; var ExpectedDateFilter: Text)
    var
        ActualStartDate: Date;
        ActualEndDate: Date;
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
    begin
        ActualStartDate := WorkDate();
        ActualEndDate := WorkDate();
        ExpectedStartDate := CalcDate('<-CM>', ActualStartDate);
        ExpectedEndDate := CalcDate('<CM>', ActualEndDate);

        MakeActualAndExpectedDateFilters(ActualStartDate, ActualEndDate, ExpectedStartDate, ExpectedEndDate,
          ActualDateFilter, ExpectedDateFilter)
    end;

    local procedure MakeActualAndExpectedDateFilters(ActualStartDate: Date; ActualEndDate: Date; ExpectedStartDate: Date; ExpectedEndDate: Date; var ActualDateFilter: Text; var ExpectedDateFilter: Text)
    begin
        ActualDateFilter := GetDateFilter(ActualStartDate, ActualEndDate);
        ExpectedDateFilter := GetDateFilter(ExpectedStartDate, ExpectedEndDate);
    end;

    local procedure MakeAccountingPeriodRandomFilter(var ActualDateFilter: Text; var ExpectedDateFilter: Text; NumberOfPeriods: Integer)
    var
        ExpectedAccPeriodStartDate: Date;
        ExpectedAccPeriodEndDate: Date;
    begin
        LibraryFiscalYear.FindAccountingPeriodStartEndDate(ExpectedAccPeriodStartDate, ExpectedAccPeriodEndDate, NumberOfPeriods);

        MakeActualAndExpectedDateFilters(
          ExpectedAccPeriodStartDate + LibraryRandom.RandIntInRange(5, 10),
          ExpectedAccPeriodEndDate - LibraryRandom.RandIntInRange(5, 10),
          ExpectedAccPeriodStartDate, ExpectedAccPeriodEndDate,
          ActualDateFilter, ExpectedDateFilter)
    end;

    local procedure VerifyDateFilter(ExpectedDateFilter: Text; ActualDateFilter: Text)
    begin
        Assert.AreEqual(ExpectedDateFilter, ActualDateFilter, IncorrectDateFilterErr);
    end;
}

