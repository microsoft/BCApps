codeunit 134210 "Charts - Test AL Charts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Business Chart Buffer] [UT]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        NotAllowedInsertErrMsg: Label 'You cannot insert into table %1.';
        NoOfPeriodsErrMsg: Label 'Wrong number of periods for Period Length <%1> from %2 to %3.';
        NotAllowedDataType: Label 'Data Type must be Integer or Decimal for Measure %1.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcDateFor0D()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        Assert.AreEqual(0D, BusChartBuf.CalcFromDate(0D), 'Empty Date expected');
        Assert.AreEqual(0D, BusChartBuf.CalcToDate(0D), 'Empty Date expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForSameDay()
    var
        PeriodLength: Option;
    begin
        for PeriodLength := 0 to 4 do
            VerifyCalcNoOfPeriods(WorkDate(), WorkDate(), PeriodLength, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForInvertedPeriodDay()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Day;
        VerifyCalcNoOfPeriods(WorkDate(), WorkDate() - 1, BusChartBuf."Period Length", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForDay()
    var
        BusChartBuf: Record "Business Chart Buffer";
        FromDate: Date;
        ToDate: Date;
    begin
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Day;
        FromDate := WorkDate();
        ToDate := FromDate + LibraryRandom.RandInt(10);
        VerifyCalcNoOfPeriods(FromDate, ToDate, BusChartBuf."Period Length", ToDate - FromDate + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForTwoPeriods()
    var
        BusChartBuf: Record "Business Chart Buffer";
        PeriodLength: Option;
        FromDate: Date;
        ToDate: Date;
    begin
        FromDate := WorkDate() + LibraryRandom.RandInt(500);
        for PeriodLength := 0 to 4 do begin
            BusChartBuf."Period Length" := PeriodLength;
            ToDate := BusChartBuf.CalcToDate(FromDate);
            VerifyCalcNoOfPeriods(FromDate, ToDate + 1, PeriodLength, 2);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForOnePeriod()
    var
        BusChartBuf: Record "Business Chart Buffer";
        PeriodLength: Option;
        FromDate: Date;
        ToDate: Date;
    begin
        ToDate := WorkDate() + LibraryRandom.RandInt(500);
        for PeriodLength := 0 to 4 do begin
            BusChartBuf."Period Length" := PeriodLength;
            FromDate := BusChartBuf.CalcFromDate(ToDate);
            VerifyCalcNoOfPeriods(FromDate, ToDate, PeriodLength, 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForWeek()
    var
        BusChartBuf: Record "Business Chart Buffer";
        ToDate: Date;
        Number: Integer;
    begin
        Number := LibraryRandom.RandInt(100);
        ToDate := CalcDate(StrSubstNo('<%1W>', Number), WorkDate());
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Week;
        VerifyCalcNoOfPeriods(WorkDate(), ToDate, BusChartBuf."Period Length", Number + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForWeek53()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifyCalcNoOfPeriods(DMY2Date(31, 12, 2012), DMY2Date(1, 1, 2013), BusChartBuf."Period Length"::Week, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForMonth()
    var
        BusChartBuf: Record "Business Chart Buffer";
        ToDate: Date;
        Number: Integer;
    begin
        Number := LibraryRandom.RandInt(20);
        ToDate := CalcDate(StrSubstNo('<%1M>', Number), WorkDate());
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Month;
        VerifyCalcNoOfPeriods(WorkDate(), ToDate, BusChartBuf."Period Length", Number + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForQuarter()
    var
        BusChartBuf: Record "Business Chart Buffer";
        ToDate: Date;
        Number: Integer;
    begin
        Number := LibraryRandom.RandInt(10);
        ToDate := CalcDate(StrSubstNo('<%1Q>', Number), WorkDate());
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Quarter;
        VerifyCalcNoOfPeriods(WorkDate(), ToDate, BusChartBuf."Period Length", Number + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcNoOfPeriodsForYear()
    var
        BusChartBuf: Record "Business Chart Buffer";
        ToDate: Date;
        Number: Integer;
    begin
        Number := LibraryRandom.RandInt(5);
        ToDate := CalcDate(StrSubstNo('<%1Y>', Number), WorkDate());
        BusChartBuf."Period Length" := BusChartBuf."Period Length"::Year;
        VerifyCalcNoOfPeriods(WorkDate(), ToDate, BusChartBuf."Period Length", Number + 1);
    end;

    local procedure VerifyCalcNoOfPeriods(FromDate: Date; ToDate: Date; PeriodLength: Option; ExpectedValue: Integer)
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        BusChartBuf."Period Length" := PeriodLength;
        Assert.AreEqual(
          ExpectedValue, BusChartBuf.CalcNumberOfPeriods(FromDate, ToDate),
          StrSubstNo(NoOfPeriodsErrMsg, BusChartBuf."Period Length", FromDate, ToDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetsForEmptyMap()
    var
        TempBusChartMap: Record "Business Chart Map" temporary;
    begin
        Assert.AreEqual(-1, TempBusChartMap.GetIndex(''), 'Index <-1> expected for not existing map');
        Assert.AreEqual('', TempBusChartMap.GetValueString(0), 'Empty Value expected for not existing map');
        Assert.AreEqual('', TempBusChartMap.GetName(0), 'Empty Name expected for not existing map');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMapIndex()
    var
        TempBusChartMap: Record "Business Chart Map" temporary;
        MapName: Text[80];
        ExpectedIndex: Integer;
    begin
        MapName := 'X';
        ExpectedIndex := 1;
        TempBusChartMap.Add('0', '');
        TempBusChartMap.Add(MapName, '');
        TempBusChartMap.Add('2', '');

        Assert.AreEqual(
          ExpectedIndex, TempBusChartMap.GetIndex(MapName), StrSubstNo('Index <%1> is expected for map <%2>', ExpectedIndex, MapName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMapValue()
    var
        TempBusChartMap: Record "Business Chart Map" temporary;
        MapName: Text[80];
        ExpectedValue: Text[30];
    begin
        ExpectedValue := Format(Today, 0, 9);
        MapName := 'X';
        TempBusChartMap.Add(MapName, ExpectedValue);

        Assert.AreEqual(
          ExpectedValue, TempBusChartMap.GetValueString(TempBusChartMap.GetIndex(MapName)), StrSubstNo('Expected Value <%1> for map <%2>', ExpectedValue, MapName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotAllowedInsertToBuffer()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        asserterror BusChartBuf.Insert(true);
        Assert.ExpectedError(StrSubstNo(NotAllowedInsertErrMsg, BusChartBuf.TableCaption()))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetGetValue()
    var
        BusChartBuf: Record "Business Chart Buffer";
        Value: Variant;
        ExpectedInt: Integer;
        ActualInt: Integer;
    begin
        CreateChart(BusChartBuf, 1, 1);
        ExpectedInt := Date2DMY(WorkDate(), 3);
        BusChartBuf.SetValue(GetMeasureName(1), 0, ExpectedInt);

        BusChartBuf.GetValue(GetMeasureName(1), 0, Value);
        Evaluate(ActualInt, Format(Value, 0, 9), 9);
        Assert.AreEqual(ExpectedInt, ActualInt, StrSubstNo('Expected value: %1', ExpectedInt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIterateMeasures()
    var
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapMeasure: Record "Business Chart Map";
        ExpectedName: Text[80];
    begin
        ExpectedName := GetMeasureName(2);
        CreateChart(BusChartBuf, 2, 0);
        BusChartBuf.FindFirstMeasure(BusChartMapMeasure);
        BusChartBuf.NextMeasure(BusChartMapMeasure);
        Assert.AreEqual(ExpectedName, BusChartMapMeasure.Name, StrSubstNo('Expected measure name: %1', ExpectedName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotExistedNextMeasure()
    var
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapMeasure: Record "Business Chart Map";
    begin
        CreateChart(BusChartBuf, 2, 0);
        BusChartBuf.FindFirstMeasure(BusChartMapMeasure);
        BusChartBuf.NextMeasure(BusChartMapMeasure);
        Assert.IsFalse(BusChartBuf.NextMeasure(BusChartMapMeasure), 'No measure expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIterateColumns()
    var
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapColumn: Record "Business Chart Map";
        ExpectedName: Text[80];
    begin
        ExpectedName := GetColumnName(2);
        CreateChart(BusChartBuf, 0, 2);
        BusChartBuf.FindFirstColumn(BusChartMapColumn);
        BusChartBuf.NextColumn(BusChartMapColumn);
        Assert.AreEqual(ExpectedName, BusChartMapColumn.Name, StrSubstNo('Expected column name: %1', ExpectedName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotExistedNextColumn()
    var
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMapColumn: Record "Business Chart Map";
    begin
        CreateChart(BusChartBuf, 0, 2);
        BusChartBuf.FindFirstColumn(BusChartMapColumn);
        BusChartBuf.NextColumn(BusChartMapColumn);
        Assert.IsFalse(BusChartBuf.NextColumn(BusChartMapColumn), 'No column expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetXValue()
    var
        BusChartBuf: Record "Business Chart Buffer";
        Value: Variant;
        ExpectedValue: Text[80];
        Index: Integer;
    begin
        CreateChart(BusChartBuf, 0, 3);
        Index := 1;
        ExpectedValue := GetColumnName(Index + 1);

        BusChartBuf.GetXValue(Index, Value);
        Assert.AreEqual(ExpectedValue, Format(Value, 0, 9), StrSubstNo('Expected value: %1', ExpectedValue));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetXValueAsDate()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis('Date', BusChartBuf."Data Type"::DateTime);
        BusChartBuf.AddColumn(Today);

        Assert.AreEqual(Today, BusChartBuf.GetXValueAsDate(0), StrSubstNo('Expected value: %1', Today));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMeasureValueString()
    var
        BusChartBuf: Record "Business Chart Buffer";
        Index: Integer;
    begin
        CreateChart(BusChartBuf, 4, 0);
        Index := 2;
        Assert.AreEqual(
          Format(Index + 1), BusChartBuf.GetMeasureValueString(Index), StrSubstNo('Expected value <%1> for index <%2>', Index + 1, Index));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCurrMeasureValueString()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        CreateChart(BusChartBuf, 4, 0);
        BusChartBuf."Drill-Down Measure Index" := 2;
        Assert.AreEqual(
          Format(BusChartBuf."Drill-Down Measure Index" + 1), BusChartBuf.GetCurrMeasureValueString(),
          StrSubstNo(
            'Expected value <%1> for index <%2>', BusChartBuf."Drill-Down Measure Index" + 1, BusChartBuf."Drill-Down Measure Index"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureDataTypeInteger()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifyAllowedMeasureDateType(BusChartBuf."Data Type"::Integer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureDataTypeDecimal()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifyAllowedMeasureDateType(BusChartBuf."Data Type"::Decimal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotAllowedMeasureDataTypeString()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        asserterror VerifyAllowedMeasureDateType(BusChartBuf."Data Type"::String);
        Assert.ExpectedError(StrSubstNo(NotAllowedDataType, GetMeasureName(0)))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotAllowedMeasureDataTypeDateTime()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        asserterror VerifyAllowedMeasureDateType(BusChartBuf."Data Type"::DateTime);
        Assert.ExpectedError(StrSubstNo(NotAllowedDataType, GetMeasureName(0)))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOutOfIndex()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        CreateChart(BusChartBuf, 1, 1);

        asserterror BusChartBuf.SetValueByIndex(-1, -1, 1);
        asserterror BusChartBuf.SetValueByIndex(1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSystemTypeString()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifySystemTypeOnXAxis(BusChartBuf."Data Type"::String);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSystemTypeInteger()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifySystemTypeOnXAxis(BusChartBuf."Data Type"::Integer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSystemTypeDecimal()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifySystemTypeOnXAxis(BusChartBuf."Data Type"::Decimal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSystemTypeDateTime()
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        VerifySystemTypeOnXAxis(BusChartBuf."Data Type"::DateTime);
    end;

    local procedure VerifySystemTypeOnXAxis(DataType: Option)
    var
        BusChartBuf: Record "Business Chart Buffer";
        ErrMsg: Text;
    begin
        BusChartBuf.Initialize();
        BusChartBuf."Data Type" := DataType;
        BusChartBuf.SetXAxis('Date', BusChartBuf."Data Type");

        if BusChartBuf."Data Type" = BusChartBuf."Data Type"::DateTime then begin
            ErrMsg := StrSubstNo('Expected type <DateTime> for X axis for passed type <%1>', BusChartBuf."Data Type");
            Assert.IsTrue(BusChartBuf.IsXAxisDateTime(), ErrMsg)
        end else begin
            ErrMsg := StrSubstNo('Not expected type <DateTime> for X axis for passed type <%1>', BusChartBuf."Data Type");
            Assert.IsFalse(BusChartBuf.IsXAxisDateTime(), ErrMsg)
        end;
    end;

    local procedure CreateChart(var BusChartBuf: Record "Business Chart Buffer"; MeasuresCount: Integer; ColumnsCount: Integer)
    var
        i: Integer;
        j: Integer;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.SetXAxis('Column_No.', BusChartBuf."Data Type"::String);
        for i := 1 to MeasuresCount do
            BusChartBuf.AddIntegerMeasure(GetMeasureName(i), i, BusChartBuf."Chart Type"::Point);
        for j := 1 to ColumnsCount do begin
            BusChartBuf.AddColumn(GetColumnName(j));
            for i := 1 to MeasuresCount do
                BusChartBuf.SetValueByIndex(i - 1, j - 1, j * i);
        end;
    end;

    local procedure GetMeasureName(Index: Integer): Text[80]
    begin
        exit(StrSubstNo('Measure_%1', Index));
    end;

    local procedure GetColumnName(Index: Integer): Text[80]
    begin
        exit(StrSubstNo('col. %1', Index));
    end;

    local procedure VerifyAllowedMeasureDateType(DataType: Option)
    var
        BusChartBuf: Record "Business Chart Buffer";
    begin
        BusChartBuf.Initialize();
        BusChartBuf.AddMeasure(GetMeasureName(0), 0, DataType, 0);
    end;
}

