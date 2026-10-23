// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

codeunit 130486 "Test Input Date Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DataTools: Codeunit "Test Input Data Tools";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure PositiveAndNegativeDateOffsetsUseWorkDate()
    var
        Input: Codeunit "Test Input Json";
        FutureDate: Date;
        PastDate: Date;
    begin
        // [SCENARIO] Typed and text date resolution use the work date for both positive and negative offsets.

        // [GIVEN] Date formulas with positive and negative offsets from the work date.
        Input.Initialize('{"future":"$DateFormula-<1W>$","past":"$DateFormula-<-1W>$"}');

        // [WHEN] The formulas are read as dates.
        FutureDate := Input.Element('future').ValueAsDate();
        PastDate := Input.Element('past').ValueAsDate();

        // [THEN] Typed and text reads use the same work-date-relative results.
        Assert.AreEqual(WorkDate() + 7, FutureDate, 'Positive offsets must use the work date.');
        Assert.AreEqual(WorkDate() - 7, PastDate, 'Negative offsets must use the work date.');
        Assert.AreEqual(Format(WorkDate() + 7), Input.Element('future').ValueAsText(), 'Text reads must format the calculated date.');
        Assert.AreEqual(Format(WorkDate() - 7), Input.Element('past').ValueAsText(), 'Negative offsets must also resolve in text.');
    end;

    [Test]
    procedure CurrentMonthAndYearBoundariesResolve()
    var
        NextMonthStart: Date;
        MonthEnd: Date;
        Month: Integer;
        Year: Integer;
    begin
        // [SCENARIO] Current-month and current-year formulas resolve to the correct first and last calendar days.

        // [GIVEN] Calendar boundaries calculated independently from the placeholder resolver.
        Month := Date2DMY(WorkDate(), 2);
        Year := Date2DMY(WorkDate(), 3);
        if Month = 12 then
            NextMonthStart := DMY2Date(1, 1, Year + 1)
        else
            NextMonthStart := DMY2Date(1, Month + 1, Year);

        // [WHEN] A current-month formula is resolved.
        MonthEnd := DataTools.ResolveAsDate('$DateFormula-<CM>$');

        // [THEN] Month and year formulas resolve to their corresponding calendar boundaries.
        Assert.AreEqual(NextMonthStart - 1, MonthEnd, 'CM must resolve to the last day of the current month.');
        Assert.AreEqual(DMY2Date(1, Month, Year), DataTools.ResolveAsDate('$DateFormula-<-CM>$'), '-CM must resolve to the first day of the current month.');
        Assert.AreEqual(DMY2Date(31, 12, Year), DataTools.ResolveAsDate('$DateFormula-<CY>$'), 'CY must resolve to the last day of the current year.');
        Assert.AreEqual(DMY2Date(1, 1, Year), DataTools.ResolveAsDate('$DateFormula-<-CY>$'), '-CY must resolve to the first day of the current year.');
    end;

    [Test]
    procedure DateFormulaCanBeReadAsDateTimeAtMidnight()
    var
        Input: Codeunit "Test Input Json";
        ActualDateTime: DateTime;
    begin
        // [SCENARIO] Reading a date-only formula as a datetime supplies midnight on the calculated date.

        // [GIVEN] A date formula without a time component.
        Input.Initialize('{"date":"$DateFormula-<1D>$"}');

        // [WHEN] The value is requested as a datetime.
        ActualDateTime := Input.Element('date').ValueAsDateTime();

        // [THEN] Date-only resolution supplies midnight.
        Assert.AreEqual(
            CreateDateTime(WorkDate() + 1, 0T), ActualDateTime,
            'Reading a date formula as DateTime must preserve the midnight conversion.');
    end;

    [Test]
    procedure RepeatedAndAdjacentDateTokensResolve()
    var
        Template: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Text resolution handles every adjacent and repeated date token without skipping an occurrence.

        // [GIVEN] Adjacent and repeated date tokens in one input.
        Template := 'Dates: $DateFormula-<CD>$$DateFormula-<1D>$ / $DateFormula-<CD>$';

        // [WHEN] The complete input is resolved.
        ResolvedText := DataTools.ResolveText(Template);

        // [THEN] Every original occurrence contributes its calculated date.
        Assert.AreEqual(
            'Dates: ' + Format(WorkDate()) + Format(WorkDate() + 1) + ' / ' + Format(WorkDate()),
            ResolvedText,
            'Every original date token must resolve, including adjacent and repeated tokens.');
    end;

    [Test]
    procedure RepeatedAndAdjacentDateTimeTokensResolve()
    var
        Midnight: DateTime;
        NextDayEnd: DateTime;
        ResolvedText: Text;
    begin
        // [SCENARIO] Adjacent and repeated datetime tokens retain their independently calculated dates and times.

        // [GIVEN] Repeated datetime formulas covering midnight and the end of the following day.
        Midnight := CreateDateTime(WorkDate(), 000000T);
        NextDayEnd := CreateDateTime(WorkDate() + 1, 235959T);

        // [WHEN] Adjacent datetime tokens are resolved together.
        ResolvedText := DataTools.ResolveText(
            '$DateTimeFormula-<CD>-00:00:00$$DateTimeFormula-<1D>-23:59:59$ / $DateTimeFormula-<CD>-00:00:00$');

        // [THEN] The scanner preserves every datetime occurrence and its time.
        Assert.AreEqual(
            Format(Midnight) + Format(NextDayEnd) + ' / ' + Format(Midnight),
            ResolvedText,
            'DateTime tokens must not be confused with date tokens or skip adjacent occurrences.');
    end;

    [Test]
    procedure DateTokensStayRawInJsonExports()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Template: Text;
        Serialized: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Resolving date values leaves raw JSON exports, scalar templates, and property names unchanged.

        // [GIVEN] Date tokens used as a property name and within its value.
        Template := '$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$';
        InputObject.Add('$DateFormula-<CD>$', Template);
        InputObject.WriteTo(Serialized);
        Input.Initialize(InputObject.AsToken());

        // [WHEN] The value is read through the resolving accessor.
        ResolvedText := Input.Element('$DateFormula-<CD>$').ValueAsText();

        // [THEN] Raw scalar and object exports retain their original templates and property names.
        Assert.AreEqual(
            Format(WorkDate()) + ' / ' + Format(CreateDateTime(WorkDate(), 123011T)),
            ResolvedText, 'Date placeholders must resolve only in the value being read.');
        Assert.AreEqual(
            Template, Input.Element('$DateFormula-<CD>$').ElementValue().AsText(), 'The original date template must remain intact.');
        Assert.AreEqual(Template, Input.Element('$DateFormula-<CD>$').ToText(), 'Scalar exports must remain raw.');
        Assert.AreEqual(Serialized, Input.ToText(), 'Object exports and property names must remain raw.');
    end;

    [Test]
    procedure IncompleteDateTokensRemainLiteral()
    var
        Templates: List of [Text];
        Template: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Date and datetime references without a closing delimiter remain literal text.

        // [GIVEN] Date and datetime prefixes without a complete closing delimiter.
        Templates.Add('$DateFormula-');
        Templates.Add('$DateFormula-<CD>');
        Templates.Add('$DateTimeFormula-');
        Templates.Add('$DateTimeFormula-<CD>-12:30:11');

        foreach Template in Templates do begin
            // [WHEN] An incomplete token is resolved.
            ResolvedText := DataTools.ResolveText(Template);

            // [THEN] It remains literal rather than being partially evaluated.
            Assert.AreEqual(Template, ResolvedText, 'An incomplete date or datetime token must remain literal.');
        end;
    end;

    [Test]
    procedure DatePrefixSpellingRemainsCaseSensitive()
    var
        Template: Text;
        ResolvedText: Text;
    begin
        // [SCENARIO] Date and datetime token recognition requires the exact case-sensitive prefix spelling.

        // [GIVEN] Date and datetime references with incorrect prefix casing.
        Template := '$dateformula-<CD>$ / $DATETIMEFORMULA-<CD>$';

        // [WHEN] The references are read as resolving text.
        ResolvedText := DataTools.ResolveText(Template);

        // [THEN] Only correctly spelled prefixes are recognized.
        Assert.AreEqual(Template, ResolvedText, 'Date and DateTime prefixes must retain their fixed spelling.');
    end;

    [Test]
    procedure InvalidDateFormulaStillRaisesError()
    var
        ExpectedErrorText: Text;
        ExpectedErrorCode: Text;
    begin
        // [SCENARIO] Invalid date formulas propagate the native calculation diagnostic rather than another failure.

        // [GIVEN] The native diagnostic for this invalid formula, independent of the resolver.
        asserterror CalculateDate('<not-a-formula>');
        ExpectedErrorText := GetLastErrorText();
        ExpectedErrorCode := GetLastErrorCode();

        // [WHEN] The same formula is resolved from a token.
        asserterror DataTools.ResolveText('$DateFormula-<not-a-formula>$');

        // [THEN] The resolver propagates that specific native failure.
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    [Test]
    procedure InvalidDateTimeDateFormulaRaisesError()
    var
        ExpectedErrorText: Text;
        ExpectedErrorCode: Text;
    begin
        // [SCENARIO] A datetime token with a valid time and invalid date formula propagates the native formula error.

        // [GIVEN] The native diagnostic for an invalid formula with a valid base date.
        asserterror CalculateDate('<not-a-formula>');
        ExpectedErrorText := GetLastErrorText();
        ExpectedErrorCode := GetLastErrorCode();

        // [WHEN] The formula is read from a datetime token with a valid time.
        asserterror DataTools.ResolveAsDateTime('$DateTimeFormula-<not-a-formula>-12:30:11$');

        // [THEN] The failure is the formula error, not an unrelated parsing or runtime error.
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    [Test]
    procedure InvalidDateTimeTimeRaisesError()
    var
        ExpectedErrorText: Text;
        ExpectedErrorCode: Text;
    begin
        // [SCENARIO] Invalid explicit times propagate the native conversion error instead of defaulting to midnight.

        // [GIVEN] The native time-conversion diagnostic for an hour outside the supported range.
        asserterror EvaluateTime('25:00:00');
        ExpectedErrorText := GetLastErrorText();
        ExpectedErrorCode := GetLastErrorCode();

        // [WHEN] That time is resolved from an otherwise valid datetime token.
        asserterror DataTools.ResolveText('$DateTimeFormula-<CD>-25:00:00$');

        // [THEN] The resolver propagates the specific conversion error without substituting midnight.
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    [Test]
    procedure RawReadsSkipInvalidDateFormulas()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        DateTemplate: Text;
        DateTimeTemplate: Text;
        DateErrorText: Text;
        DateErrorCode: Text;
        TimeErrorText: Text;
        TimeErrorCode: Text;
        RawDate: Text;
        RawDateTime: Text;
    begin
        // [SCENARIO] Raw reads bypass invalid formulas while resolving and typed reads still propagate their native errors.

        // [GIVEN] Invalid date/time templates and the native diagnostics for their invalid components.
        DateTemplate := '$DateFormula-<not-a-formula>$';
        DateTimeTemplate := '$DateTimeFormula-<CD>-not-a-time$';
        asserterror CalculateDate('<not-a-formula>');
        DateErrorText := GetLastErrorText();
        DateErrorCode := GetLastErrorCode();
        asserterror EvaluateTime('not-a-time');
        TimeErrorText := GetLastErrorText();
        TimeErrorCode := GetLastErrorCode();
        InputObject.Add('date', DateTemplate);
        InputObject.Add('datetime', DateTimeTemplate);
        Input.Initialize(InputObject.AsToken());

        // [WHEN] The templates are accessed through the raw scalar reader.
        RawDate := Input.Element('date').ElementValue().AsText();
        RawDateTime := Input.Element('datetime').ElementValue().AsText();

        // [THEN] Raw reads succeed without evaluating the invalid components.
        Assert.AreEqual(DateTemplate, RawDate, 'Raw reads must not evaluate an invalid date formula.');
        Assert.AreEqual(DateTimeTemplate, RawDateTime, 'Raw reads must not evaluate an invalid time.');

        // [WHEN] Resolving or typed readers access the same templates.
        asserterror Input.Element('date').ValueAsText();

        // [THEN] Each reader propagates the corresponding native diagnostic.
        Assert.ExpectedError(DateErrorText);
        Assert.ExpectedErrorCode(DateErrorCode);
        asserterror Input.Element('date').ValueAsDate();
        Assert.ExpectedError(DateErrorText);
        Assert.ExpectedErrorCode(DateErrorCode);
        asserterror Input.Element('datetime').ValueAsText();
        Assert.ExpectedError(TimeErrorText);
        Assert.ExpectedErrorCode(TimeErrorCode);
        asserterror Input.Element('datetime').ValueAsDateTime();
        Assert.ExpectedError(TimeErrorText);
        Assert.ExpectedErrorCode(TimeErrorCode);
    end;

    [Test]
    procedure DateResolutionWorksAfterUnrelatedTextRead()
    var
        Input: Codeunit "Test Input Json";
    begin
        // [SCENARIO] An earlier plain-text read cannot cache the absence of date or datetime tokens in later input.

        // [GIVEN] The same wrapper has already returned text containing no placeholders.
        Input.Initialize('{"message":"No placeholders"}');
        Assert.AreEqual('No placeholders', Input.Element('message').ValueAsText(), 'Plain input must remain unchanged.');

        // [WHEN] The wrapper is initialized with date and datetime formulas.
        Input.Initialize('{"date":"$DateFormula-<1D>$","datetime":"$DateTimeFormula-<1D>-12:30:11$"}');

        // [THEN] Earlier reads do not cache the absence of either prefix.
        Assert.AreEqual(Format(WorkDate() + 1), Input.Element('date').ValueAsText(), 'An earlier plain read must not cache date-prefix absence.');
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate() + 1, 123011T)), Input.Element('datetime').ValueAsText(),
            'DateTime resolution must scan the current input rather than earlier input.');
    end;

    local procedure CalculateDate(Formula: Text): Date
    begin
        exit(CalcDate(Formula, DMY2Date(1, 1, 2026)));
    end;

    local procedure EvaluateTime(TimeText: Text): Time
    var
        ResultTime: Time;
    begin
        Evaluate(ResultTime, TimeText);
        exit(ResultTime);
    end;
}
