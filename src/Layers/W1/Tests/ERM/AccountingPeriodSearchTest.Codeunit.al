codeunit 134362 "Accounting Period Search Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        WrongPeriodDateErr: Label 'Wrong period.';
        DateRangeTok: Label '%1..%2', Locked = true;
        OrDateTok: Label '%1|%2', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForFirstPeriod()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for first period evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(1, 1, 2023, 31, 1, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForSingleYear()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a single year evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'year1';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(1, 1, 2023, 31, 12, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForSinglePeriod()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a single period evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p5';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);
        ExpectedDateFilterText := MakeDateRange(1, 5, 2023, 31, 5, 2023);

        // [THEN] The date filter text is set as expected.
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForSinglePeriodFullText()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a single period where the full text is used evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'period5';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(1, 5, 2023, 31, 5, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForSinglePeriodPlusDays()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a single period with the addition of ten days evaluates as expected.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p5+10d';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(11, 5, 2023, 10, 6, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForSinglePeriodMinusDays()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a single period with the substraction of five days evaluates as expected.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p5-5d';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(26, 4, 2023, 26, 5, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForPeriodInterval()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for an interval of periods evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();

        // [WHEN] Datefilter is evaluated.
        DateFilterText := 'p1..p3';
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(1, 1, 2023, 31, 3, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForMultiplePeriods()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for multiple periods evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p1|p3';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := StrSubstNo(OrDateTok, MakeDateRange(1, 1, 2023, 31, 1, 2023), MakeDateRange(1, 3, 2023, 31, 3, 2023));
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForCombinationOfPeriods()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a combination of a single period and interval of periods evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'p1|p3..p5';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := StrSubstNo(OrDateTok, MakeDateRange(1, 1, 2023, 31, 1, 2023), MakeDateRange(1, 3, 2023, 31, 5, 2023));
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForCombinationOfPeriodsAndYearsInterval()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a range of year and period evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'year..p11';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := MakeDateRange(1, 1, 2023, 30, 11, 2023);
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MakeDateFilterForCombinationOfPeriodsAndYears()
    var
        FilterTokens: Codeunit "Filter Tokens";
        DateFilterText: Text;
        ExpectedDateFilterText: Text;
    begin
        // [SCENARIO] DateFilter for a combination of year and period evaluates correctly.

        // [GIVEN] Accounting periods are initialized and datefilter is specified.
        Initialize();
        DateFilterText := 'year|p11';

        // [WHEN] Datefilter is evaluated.
        FilterTokens.MakeDateFilter(DateFilterText);

        // [THEN] The date filter text is set as expected.
        ExpectedDateFilterText := StrSubstNo(OrDateTok, MakeDateRange(1, 1, 2023, 31, 12, 2023), MakeDateRange(1, 11, 2023, 30, 11, 2023));
        Assert.AreEqual(ExpectedDateFilterText, DateFilterText, WrongPeriodDateErr);
    end;

    local procedure MakeDateRange(Day1: Integer; Month1: Integer; Year1: Integer; Day2: Integer; Month2: Integer; Year2: Integer): Text
    begin
        exit(StrSubstNo(DateRangeTok, Format(DMY2Date(Day1, Month1, Year1)), Format(DMY2Date(Day2, Month2, Year2))));
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.DeleteAll();
        WorkDate := DMY2Date(1, 1, 2023);
        LibraryFiscalYear.CreateFiscalYear();
    end;
}

