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

    var
        DataTools: Codeunit "Test Input Data Tools";
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PositiveAndNegativeDateOffsetsUseWorkDate()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize('{"future":"$DateFormula-<1W>$","past":"$DateFormula-<-1W>$"}');

        Assert.AreEqual(WorkDate() + 7, Input.Element('future').ValueAsDate(), 'Positive offsets must use the work date.');
        Assert.AreEqual(WorkDate() - 7, Input.Element('past').ValueAsDate(), 'Negative offsets must use the work date.');
        Assert.AreEqual(Format(WorkDate() + 7), Input.Element('future').ValueAsText(), 'Text reads must format the calculated date.');
        Assert.AreEqual(Format(WorkDate() - 7), Input.Element('past').ValueAsText(), 'Negative offsets must also resolve in text.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CurrentMonthAndYearBoundariesResolve()
    var
        NextMonthStart: Date;
        Month: Integer;
        Year: Integer;
    begin
        Initialize();
        Month := Date2DMY(WorkDate(), 2);
        Year := Date2DMY(WorkDate(), 3);
        if Month = 12 then
            NextMonthStart := DMY2Date(1, 1, Year + 1)
        else
            NextMonthStart := DMY2Date(1, Month + 1, Year);

        Assert.AreEqual(NextMonthStart - 1, DataTools.ResolveAsDate('$DateFormula-<CM>$'), 'CM must resolve to the last day of the current month.');
        Assert.AreEqual(DMY2Date(1, Month, Year), DataTools.ResolveAsDate('$DateFormula-<-CM>$'), '-CM must resolve to the first day of the current month.');
        Assert.AreEqual(DMY2Date(31, 12, Year), DataTools.ResolveAsDate('$DateFormula-<CY>$'), 'CY must resolve to the last day of the current year.');
        Assert.AreEqual(DMY2Date(1, 1, Year), DataTools.ResolveAsDate('$DateFormula-<-CY>$'), '-CY must resolve to the first day of the current year.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateFormulaCanBeReadAsDateTimeAtMidnight()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize('{"date":"$DateFormula-<1D>$"}');
        Assert.AreEqual(
            CreateDateTime(WorkDate() + 1, 0T), Input.Element('date').ValueAsDateTime(),
            'Reading a date formula as DateTime must preserve the midnight conversion.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedAndAdjacentDateTokensResolve()
    begin
        Initialize();
        Assert.AreEqual(
            'Dates: ' + Format(WorkDate()) + Format(WorkDate() + 1) + ' / ' + Format(WorkDate()),
            DataTools.ResolveText('Dates: $DateFormula-<CD>$$DateFormula-<1D>$ / $DateFormula-<CD>$'),
            'Every original date token must resolve, including adjacent and repeated tokens.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedAndAdjacentDateTimeTokensResolve()
    var
        Midnight: DateTime;
        NextDayEnd: DateTime;
    begin
        Initialize();
        Midnight := CreateDateTime(WorkDate(), 000000T);
        NextDayEnd := CreateDateTime(WorkDate() + 1, 235959.999T);
        Assert.AreEqual(
            Format(Midnight) + Format(NextDayEnd) + ' / ' + Format(Midnight),
            DataTools.ResolveText(
                '$DateTimeFormula-<CD>-00:00:00$$DateTimeFormula-<1D>-23:59:59.999$ / $DateTimeFormula-<CD>-00:00:00$'),
            'DateTime tokens must not be confused with date tokens or skip adjacent occurrences.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateTokensStayRawInJsonExports()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Template: Text;
        Serialized: Text;
    begin
        Initialize();
        Template := '$DateFormula-<CD>$ / $DateTimeFormula-<CD>-12:30:11$';
        InputObject.Add('$DateFormula-<CD>$', Template);
        InputObject.WriteTo(Serialized);
        Input.Initialize(InputObject.AsToken());

        Assert.AreEqual(
            Format(WorkDate()) + ' / ' + Format(CreateDateTime(WorkDate(), 123011T)),
            Input.Element('$DateFormula-<CD>$').ValueAsText(), 'Date placeholders must resolve only in the value being read.');
        Assert.AreEqual(
            Template, Input.Element('$DateFormula-<CD>$').ElementValue().AsText(), 'The original date template must remain intact.');
        Assert.AreEqual(Template, Input.Element('$DateFormula-<CD>$').ToText(), 'Scalar exports must remain raw.');
        Assert.AreEqual(Serialized, Input.ToText(), 'Object exports and property names must remain raw.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncompleteDateTokensRemainLiteral()
    begin
        Initialize();
        Assert.AreEqual('$DateFormula-', DataTools.ResolveText('$DateFormula-'), 'A date prefix alone is not a token.');
        Assert.AreEqual('$DateFormula-<CD>', DataTools.ResolveText('$DateFormula-<CD>'), 'A date token needs its closing delimiter.');
        Assert.AreEqual('$DateTimeFormula-', DataTools.ResolveText('$DateTimeFormula-'), 'A DateTime prefix alone is not a token.');
        Assert.AreEqual(
            '$DateTimeFormula-<CD>-12:30:11', DataTools.ResolveText('$DateTimeFormula-<CD>-12:30:11'),
            'An incomplete DateTime token must remain literal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DatePrefixSpellingRemainsCaseSensitive()
    var
        Template: Text;
    begin
        Initialize();
        Template := '$dateformula-<CD>$ / $DATETIMEFORMULA-<CD>$';
        Assert.AreEqual(Template, DataTools.ResolveText(Template), 'Date and DateTime prefixes must retain their fixed spelling.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidDateTimeDateFormulaRaisesError()
    begin
        Initialize();
        asserterror DataTools.ResolveAsDateTime('$DateTimeFormula-<not-a-formula>-12:30:11$');
        Assert.IsTrue(GetLastErrorText() <> '', 'An invalid DateTime date formula must raise an error.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidDateTimeTimeRaisesError()
    begin
        Initialize();
        asserterror DataTools.ResolveText('$DateTimeFormula-<CD>-25:00:00$');
        Assert.IsTrue(GetLastErrorText() <> '', 'An invalid time must not silently remain literal.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledTextSkipsInvalidDateFormulas()
    var
        Input: Codeunit "Test Input Json";
        InputObject: JsonObject;
        Template: Text;
    begin
        Initialize();
        DataTools.SetTextReplacementsEnabled(false);
        Template := '$DateFormula-<not-a-formula>$ / $DateTimeFormula-<CD>-not-a-time$';
        InputObject.Add('message', Template);
        Input.Initialize(InputObject.AsToken());

        Assert.AreEqual(Template, Input.Element('message').ValueAsText(), 'Disabled text reads must not evaluate even invalid formulas.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateResolutionWorksAfterUnrelatedTextRead()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize('{"message":"No placeholders"}');
        Assert.AreEqual('No placeholders', Input.Element('message').ValueAsText(), 'Plain input must remain unchanged.');

        Input.Initialize('{"date":"$DateFormula-<1D>$","datetime":"$DateTimeFormula-<1D>-12:30:11$"}');
        Assert.AreEqual(Format(WorkDate() + 1), Input.Element('date').ValueAsText(), 'An earlier plain read must not cache date-prefix absence.');
        Assert.AreEqual(
            Format(CreateDateTime(WorkDate() + 1, 123011T)), Input.Element('datetime').ValueAsText(),
            'DateTime resolution must scan the current input rather than earlier input.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateTimeBoundariesPreserveMilliseconds()
    var
        Input: Codeunit "Test Input Json";
    begin
        Initialize();
        Input.Initialize(
            '{"midnight":"$DateTimeFormula-<CD>-00:00:00$","first":"$DateTimeFormula-<CD>-00:00:00.001$","last":"$DateTimeFormula-<CD>-23:59:59.999$"}');

        Assert.AreEqual(CreateDateTime(WorkDate(), 000000T), Input.Element('midnight').ValueAsDateTime(), 'Explicit midnight must be preserved.');
        Assert.AreEqual(
            CreateDateTime(WorkDate(), 000000.001T), Input.Element('first').ValueAsDateTime(), 'The first millisecond must not be rounded to midnight.');
        Assert.AreEqual(
            CreateDateTime(WorkDate(), 235959.999T), Input.Element('last').ValueAsDateTime(), 'The final millisecond must not roll into the next day.');
    end;

    local procedure Initialize()
    begin
        DataTools.SetTextReplacementsEnabled(true);
    end;
}
