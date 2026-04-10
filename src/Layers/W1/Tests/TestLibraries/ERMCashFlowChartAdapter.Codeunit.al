codeunit 130090 "ERM Cash Flow Chart Adapter"
{

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        CurrSourceType: Enum "Cash Flow Source Type";
        MaxSourceType: Enum "Cash Flow Source Type";
        IsInitialized: Boolean;
        UnexpectedCFAmountInPeriod: Label 'Unexpected Cash Flow amount in period %1.';
        UnexpectedPositiveCFAmountInPeriod: Label 'Unexpected positive Cash Flow amount in period %1.';
        UnexpectedNegativeCFAmountInPeriod: Label 'Unexpected negative Cash Flow amount in period %1.';
        UnexpectedCFAmountPerSourceTypeInPeriod: Label 'Unexpected Cash Flow amount for source type %1 in period %2.';
        UnexpectedCFAmountPerAccountTypeInPeriod: Label 'Unexpected Cash Flow amount for account %1 in period %2.';

    [Scope('OnPrem')]
    procedure Day()
    begin
        SetCFChartSetupPeriodLength(CashFlowChartSetup."Period Length"::Day);
    end;

    [Scope('OnPrem')]
    procedure Week()
    begin
        SetCFChartSetupPeriodLength(CashFlowChartSetup."Period Length"::Week);
    end;

    [Scope('OnPrem')]
    procedure Month()
    begin
        SetCFChartSetupPeriodLength(CashFlowChartSetup."Period Length"::Month);
    end;

    [Scope('OnPrem')]
    procedure Quarter()
    begin
        SetCFChartSetupPeriodLength(CashFlowChartSetup."Period Length"::Quarter);
    end;

    [Scope('OnPrem')]
    procedure Year()
    begin
        SetCFChartSetupPeriodLength(CashFlowChartSetup."Period Length"::Year);
    end;

    [Scope('OnPrem')]
    procedure Sign()
    begin
        SetGroupingStackOption(CashFlowChartSetup."Group By"::"Positive/Negative");
    end;

    [Scope('OnPrem')]
    procedure Account()
    begin
        SetGroupingStackOption(CashFlowChartSetup."Group By"::"Account No.");
    end;

    [Scope('OnPrem')]
    procedure SourceType()
    begin
        SetGroupingStackOption(CashFlowChartSetup."Group By"::"Source Type");
    end;

    [Scope('OnPrem')]
    procedure SalesOrder()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CurrSourceType := CFForecastEntry."Source Type"::"Sales Orders";
    end;

    [Scope('OnPrem')]
    procedure MultiSource()
    begin
        CurrSourceType := CurrSourceType::" ";
    end;

    [Scope('OnPrem')]
    procedure Period1()
    var
        CFDate: Date;
        CFAmount: Decimal;
    begin
        CFDate := GetCFDateByPeriod(1);
        CFAmount := LibraryRandom.RandDec(1000, 2);
        InsertCFLedgerEntry(CashFlowForecast."No.", CurrSourceType, CFDate, CFAmount);
    end;

    [Scope('OnPrem')]
    procedure Period2()
    var
        CFDate: Date;
        CFAmount: Decimal;
    begin
        CFDate := GetCFDateByPeriod(2);
        CFAmount := LibraryRandom.RandDec(1000, 2);
        InsertCFLedgerEntry(CashFlowForecast."No.", CurrSourceType, CFDate, CFAmount);
    end;

    [Scope('OnPrem')]
    procedure Period3()
    var
        CFDate: Date;
        CFAmount: Decimal;
    begin
        CFDate := GetCFDateByPeriod(3);
        CFAmount := LibraryRandom.RandDec(1000, 2);
        InsertCFLedgerEntry(CashFlowForecast."No.", CurrSourceType, CFDate, CFAmount);
    end;

    [Scope('OnPrem')]
    procedure AccChart()
    var
        BusinessChartMapMeasure: Record "Business Chart Map";
        BusinessChartMapColumn: Record "Business Chart Map";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        Value: Variant;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
        NoOfActualPeriods: Integer;
        TestPeriod: Integer;
        FromDate: Date;
        ToDate: Date;
    begin
        // Verify the staircase chart
        // Amounts per period should be accumulated, if there is no change in amounts (=0),
        // the staircase should remain on its last known value!

        // Set chart type to staircase chart
        SetCFChartSetupShow(CashFlowChartSetup.Show::"Accumulated Cash");

        FillAndPostJournalWithDemoData();

        // Trigger updating chart data source
        CFChartMgt.UpdateData(BusChartBuf);

        // Verify
        NoOfActualPeriods := 0;
        BusChartBuf.FindFirstMeasure(BusinessChartMapMeasure);
        repeat
            if BusChartBuf.FindFirstColumn(BusinessChartMapColumn) then
                repeat
                    NoOfActualPeriods += 1;
                    TestPeriod := NoOfActualPeriods + (NoOfActualPeriods div 2); // 2 because test period 1 and 2 are combined
                    ExpectedAmount := CalcExpectedAmtCummulatedByPeriod(TestPeriod);
                    EvaluateCFDateRangeByPeriod(TestPeriod, FromDate, ToDate);
                    BusChartBuf.GetValue(BusinessChartMapMeasure.Name, BusinessChartMapColumn.Index, Value);
                    Evaluate(ActualAmount, Format(Value));
                    Assert.AreEqual(ExpectedAmount, ActualAmount, StrSubstNo(UnexpectedCFAmountInPeriod, NoOfActualPeriods));
                until (not BusChartBuf.NextColumn(BusinessChartMapColumn)) or (NoOfActualPeriods < 2);
        until not BusChartBuf.NextMeasure(BusinessChartMapMeasure);
    end;

    [Scope('OnPrem')]
    procedure CFChart()
    var
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        // Verify the stack chart

        // Set chart type to stack chart
        SetCFChartSetupShow(CashFlowChartSetup.Show::"Change in Cash");

        FillAndPostJournalWithDemoData();

        // Trigger updating chart data source
        CFChartMgt.UpdateData(BusChartBuf);

        // Calculated expected amounts and verify actuals based on the selected group stack option and periods
        case CashFlowChartSetup."Group By" of
            CashFlowChartSetup."Group By"::"Positive/Negative":
                VerifyPositiveNegativeStackTypeAmounts(BusChartBuf);
            CashFlowChartSetup."Group By"::"Account No.":
                VerifyAccountStackTypeAmounts(BusChartBuf);
            CashFlowChartSetup."Group By"::"Source Type":
                VerifySourceTypeStackTypeAmounts(BusChartBuf);
        end;
    end;

    local procedure FillAndPostJournalWithDemoData()
    var
        I: Integer;
        ConsiderSource: array[16] of Boolean;
    begin
        // If no source type has been explicitly specified, fill and post journal with demo data
        if CurrSourceType = CurrSourceType::" " then begin
            for I := 1 to MaxSourceType.AsInteger() do
                ConsiderSource[I] := true;
            LibraryCF.FillJournal(ConsiderSource, CashFlowForecast."No.", false);
            LibraryCF.PostJournal();
        end;
    end;

    local procedure CalcExpectedAmtCummulatedByPeriod(Period: Integer): Decimal
    var
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := 0;
        CFForecastEntry.Reset();
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        SetCFDateRangeFilterOnCFLedgEntry(Period);
        if not CFForecastEntry.FindSet() then
            exit(0); // There are no CF entries

        repeat
            ExpectedAmount += CFForecastEntry."Amount (LCY)";
        until CFForecastEntry.Next() = 0;
        exit(ExpectedAmount);
    end;

    local procedure CalcExpectedAmtByPeriodAndSign(Period: Integer; PositiveSign: Boolean): Decimal
    var
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := 0;
        CFForecastEntry.Reset();
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        SetCFDateRangeFilterOnCFLedgEntry(Period);
        if PositiveSign then
            CFForecastEntry.SetFilter("Amount (LCY)", '>0')
        else
            CFForecastEntry.SetFilter("Amount (LCY)", '<0');
        if not CFForecastEntry.FindSet() then
            exit(0); // There are no CF entries

        repeat
            ExpectedAmount += CFForecastEntry."Amount (LCY)";
        until CFForecastEntry.Next() = 0;
        exit(ExpectedAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcExpectedAmtByPeriodAndSourceType(Period: Integer; SrcType: Option): Decimal
    var
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := 0;
        CFForecastEntry.Reset();
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.SetRange("Source Type", SrcType);
        SetCFDateRangeFilterOnCFLedgEntry(Period);
        if not CFForecastEntry.FindSet() then
            exit(0); // There are no CF entries

        repeat
            ExpectedAmount += CFForecastEntry."Amount (LCY)";
        until CFForecastEntry.Next() = 0;
        exit(ExpectedAmount);
    end;

    local procedure CalcdateRangeFromAndToByPeriod(Period: Integer; DatePeriodIdentifier: Char; ReferenceDate: Date; var RangeFrom: Date; var RangeTo: Date)
    begin
        case Period of
            1, 2:
                begin
                    if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                        RangeFrom := ReferenceDate
                    else
                        RangeFrom := CalcDate(StrSubstNo('<-C%1>', DatePeriodIdentifier), ReferenceDate);
                    RangeTo := CalcDate(StrSubstNo('<C%1>', DatePeriodIdentifier), ReferenceDate);
                end;
            3:
                begin
                    RangeFrom := CalcDate(StrSubstNo('<C%1+1D>', DatePeriodIdentifier), ReferenceDate);
                    RangeTo := CalcDate(StrSubstNo('<C%1+1%1>', DatePeriodIdentifier), ReferenceDate);
                end;
        end;
    end;

    local procedure CalcFromAndToDateFromLedgerEntries(var FromDate: Date; var ToDate: Date)
    begin
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.", "Cash Flow Date");
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        if CFForecastEntry.IsEmpty() then begin
            FromDate := WorkDate();
            ToDate := WorkDate();
        end else begin
            CFForecastEntry.FindFirst();
            FromDate := CFForecastEntry."Cash Flow Date";
            CFForecastEntry.FindLast();
            ToDate := CFForecastEntry."Cash Flow Date";
        end;
    end;

    local procedure EvaluateCFDateRangeByPeriod(Period: Integer; var RangeFrom: Date; var RangeTo: Date)
    var
        ReferenceDate: Date;
    begin
        ReferenceDate := WorkDate();
        RangeFrom := ReferenceDate;
        RangeTo := ReferenceDate;

        case CashFlowChartSetup."Period Length" of
            CashFlowChartSetup."Period Length"::Day:
                case Period of
                    1, 2:
                        begin
                            RangeFrom := ReferenceDate;
                            RangeTo := RangeFrom;
                        end;
                    3:
                        begin
                            RangeFrom := CalcDate('<1D>', ReferenceDate); // Next day
                            RangeTo := RangeFrom;
                        end;
                end;
            CashFlowChartSetup."Period Length"::Week:
                CalcdateRangeFromAndToByPeriod(Period, 'W', ReferenceDate, RangeFrom, RangeTo);
            CashFlowChartSetup."Period Length"::Month:
                CalcdateRangeFromAndToByPeriod(Period, 'M', ReferenceDate, RangeFrom, RangeTo);
            CashFlowChartSetup."Period Length"::Quarter:
                CalcdateRangeFromAndToByPeriod(Period, 'Q', ReferenceDate, RangeFrom, RangeTo);
            CashFlowChartSetup."Period Length"::Year:
                CalcdateRangeFromAndToByPeriod(Period, 'Y', ReferenceDate, RangeFrom, RangeTo);
        end
    end;

    local procedure GetCFDateByPeriod(Period: Integer): Date
    var
        ReferenceDate: Date;
    begin
        ReferenceDate := WorkDate();

        case CashFlowChartSetup."Period Length" of
            CashFlowChartSetup."Period Length"::Day:
                case Period of
                    1:
                        exit(ReferenceDate); // current day
                    2:
                        exit(ReferenceDate); // current day
                    3:
                        exit(CalcDate('<1D>', ReferenceDate)); // next day
                end;
            CashFlowChartSetup."Period Length"::Week:
                case Period of
                    1:
                        if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                            exit(ReferenceDate)
                        else
                            exit(CalcDate('<CW-3D>', ReferenceDate)); // middle of the week
                    2:
                        exit(CalcDate('<CW>', ReferenceDate)); // last day of current week
                    3:
                        exit(CalcDate('<CW+1D>', ReferenceDate)); // first day of next week
                end;
            CashFlowChartSetup."Period Length"::Month:
                case Period of
                    1:
                        if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                            exit(ReferenceDate)
                        else
                            exit(CalcDate('<CM-2W>', ReferenceDate)); // middle of the month
                    2:
                        exit(CalcDate('<CM>', ReferenceDate)); // last day of current month
                    3:
                        exit(CalcDate('<CM+1D>', ReferenceDate)); // first day of next month
                end;
            CashFlowChartSetup."Period Length"::Quarter:
                case Period of
                    1:
                        if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                            exit(ReferenceDate)
                        else
                            exit(CalcDate('<CQ-1W>', ReferenceDate)); // middle of the quarter
                    2:
                        exit(CalcDate('<CQ>', ReferenceDate)); // last day of current quarter
                    3:
                        exit(CalcDate('<CQ+1D>', ReferenceDate)); // first day of next quarter
                end;
            CashFlowChartSetup."Period Length"::Year:
                case Period of
                    1:
                        if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
                            exit(ReferenceDate)
                        else
                            exit(CalcDate('<CY-6M>', ReferenceDate)); // middle of the year
                    2:
                        exit(CalcDate('<CY>', ReferenceDate)); // last day of current year
                    3:
                        exit(CalcDate('<CY+1D>', ReferenceDate)); // first day of next year
                end;
        end
    end;

    local procedure GetCFAccountFromSourceType(SourceType: Enum "Cash Flow Source Type"): Code[20]
    var
        CFAccount: Record "Cash Flow Account";
    begin
        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
        CFAccount.FindSet();
        CFAccount.Next(SourceType.AsInteger());
        exit(CFAccount."No.");
    end;

    local procedure GetDecimalValueFromChartDataSource(var BusChartBuf: Record "Business Chart Buffer"; MeasureCaption: Text[249]; XIndex: Integer): Decimal
    var
        Value: Variant;
        TmpAmount: Decimal;
    begin
        BusChartBuf.GetValue(MeasureCaption, XIndex, Value);
        if not Evaluate(TmpAmount, Format(Value)) then
            exit(0);
        exit(TmpAmount);
    end;

    local procedure GetNoOfActualPeriods(): Integer
    var
        BusChartBuf: Record "Business Chart Buffer";
        FromDate: Date;
        ToDate: Date;
    begin
        CalcFromAndToDateFromLedgerEntries(FromDate, ToDate);
        if CashFlowChartSetup."Start Date" = CashFlowChartSetup."Start Date"::"Working Date" then
            FromDate := WorkDate();
        if CurrSourceType <> CurrSourceType::" " then begin
            BusChartBuf."Period Length" := CashFlowChartSetup."Period Length";
            exit(BusChartBuf.CalcNumberOfPeriods(FromDate, ToDate));
        end else
            exit(2); // multi-source; based on the [1,2][3] test periods, 2 is a boundary test within period 1
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        // Test fx initialization
        if not IsInitialized then begin
            IsInitialized := true;
            Commit();
        end;

        // Custom init per run
        InitializeCashFlowChartSetup(CashFlowChartSetup.Show::"Change in Cash");
        SetGroupingStackOption(CashFlowChartSetup."Group By"::"Positive/Negative");
        LibraryCF.CreateCashFlowCard(CashFlowForecast);
        SetChartCFNoInSetup(CashFlowForecast."No.");
        CFForecastEntry.Reset();
        CFForecastEntry.DeleteAll();
        CurrSourceType := CurrSourceType::" "; // Multi-Source
        MaxSourceType := CFForecastEntry."Source Type"::Job;
    end;

    local procedure InitializeCashFlowChartSetup(ChartSetupShow: Option)
    begin
        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();

        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(CashFlowChartSetup."User ID"));
        CashFlowChartSetup."Start Date" := CashFlowChartSetup."Start Date"::"Working Date";
        CashFlowChartSetup."Period Length" := CashFlowChartSetup."Period Length"::Day;
        CashFlowChartSetup.Show := ChartSetupShow;
        CashFlowChartSetup.Insert();
    end;

    local procedure InsertCFLedgerEntry(CFNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CFDate: Date; Amount: Decimal)
    var
        EntryNo: Integer;
    begin
        if CFForecastEntry.FindLast() then
            EntryNo := CFForecastEntry."Entry No.";

        CFForecastEntry.Init();
        CFForecastEntry."Entry No." := EntryNo + 1;
        CFForecastEntry."Cash Flow Forecast No." := CFNo;
        CFForecastEntry."Source Type" := SourceType;
        CFForecastEntry."Cash Flow Date" := CFDate;
        CFForecastEntry."Cash Flow Account No." := GetCFAccountFromSourceType(SourceType);
        CFForecastEntry.Validate("Amount (LCY)", Amount);
        CFForecastEntry.Insert();
    end;

    local procedure SetCFChartSetupPeriodLength(PeriodLength: Option)
    begin
        CashFlowChartSetup."Period Length" := PeriodLength;
        CashFlowChartSetup.Modify(true);
    end;

    local procedure SetCFChartSetupShow(ChartSetupShow: Option)
    begin
        CashFlowChartSetup.Show := ChartSetupShow;
        CashFlowChartSetup.Modify(true);
    end;

    local procedure SetCFDateRangeFilterOnCFLedgEntry(Period: Integer)
    var
        RangeFrom: Date;
        RangeTo: Date;
    begin
        EvaluateCFDateRangeByPeriod(Period, RangeFrom, RangeTo);
        CFForecastEntry.SetRange("Cash Flow Date", RangeFrom, RangeTo);
    end;

    local procedure SetChartCFNoInSetup(ChartCashFlowNo: Code[20])
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        CashFlowSetup.Get();
        CashFlowSetup."CF No. on Chart in Role Center" := ChartCashFlowNo;
        CashFlowSetup.Modify(true);
    end;

    local procedure SetGroupingStackOption(GroupingOption: Option)
    begin
        CashFlowChartSetup."Group By" := GroupingOption;
        CashFlowChartSetup.Modify(true);
    end;

    local procedure VerifyPositiveNegativeStackTypeAmounts(var BusChartBuf: Record "Business Chart Buffer")
    var
        BusinessChartMapMeasure: Record "Business Chart Map";
        TestPeriod: Integer;
        I: Integer;
        NoOfActualPeriods: Integer;
        PosActualAmount: Decimal;
        NegActualAmount: Decimal;
        Positive: Boolean;
    begin
        NoOfActualPeriods := GetNoOfActualPeriods();

        for I := 1 to NoOfActualPeriods do begin
            // test periods are [1,2],[3], where 2 represents a boundary within actual period 1
            TestPeriod := I + (I div 2); // 2 because test period 1 and 2 are combined

            if BusChartBuf.FindFirstMeasure(BusinessChartMapMeasure) then
                repeat
                    Evaluate(Positive, BusinessChartMapMeasure."Value String", 9);
                    if Positive then
                        PosActualAmount := GetDecimalValueFromChartDataSource(BusChartBuf, BusinessChartMapMeasure.Name, I - 1)
                    else
                        NegActualAmount := GetDecimalValueFromChartDataSource(BusChartBuf, BusinessChartMapMeasure.Name, I - 1);
                until not BusChartBuf.NextMeasure(BusinessChartMapMeasure);

            Assert.AreEqual(CalcExpectedAmtByPeriodAndSign(TestPeriod, true), PosActualAmount,
              StrSubstNo(UnexpectedPositiveCFAmountInPeriod, I));
            Assert.AreEqual(CalcExpectedAmtByPeriodAndSign(TestPeriod, false), NegActualAmount,
              StrSubstNo(UnexpectedNegativeCFAmountInPeriod, I));
        end;
    end;

    local procedure VerifySourceTypeStackTypeAmounts(var BusChartBuf: Record "Business Chart Buffer")
    var
        FromDate: Date;
        ToDate: Date;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
        NoOfActualPeriods: Integer;
        I: Integer;
        J: Integer;
    begin
        NoOfActualPeriods := GetNoOfActualPeriods();

        for I := 1 to NoOfActualPeriods do begin
            CFForecastEntry.Reset();
            CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
            EvaluateCFDateRangeByPeriod(I + (I div 2), FromDate, ToDate);
            CFForecastEntry.SetRange("Cash Flow Date", FromDate, ToDate);
            // loop through all source types
            for J := 1 to MaxSourceType.AsInteger() do begin
                // find all related cf entries
                CFForecastEntry.SetRange("Source Type", J);
                if CFForecastEntry.FindSet() then begin
                    // calc expected amount
                    ExpectedAmount := 0;
                    repeat
                        ExpectedAmount += CFForecastEntry."Amount (LCY)";
                    until CFForecastEntry.Next() = 0;

                    ActualAmount := GetDecimalValueFromChartDataSource(BusChartBuf,
                        Format(CFForecastEntry."Source Type"), I - 1);

                    Assert.AreEqual(ExpectedAmount, ActualAmount,
                      StrSubstNo(UnexpectedCFAmountPerSourceTypeInPeriod, Format(CFForecastEntry."Source Type"), I));
                end;
            end;
        end;
    end;

    local procedure VerifyAccountStackTypeAmounts(var BusChartBuf: Record "Business Chart Buffer")
    var
        CFAccount: Record "Cash Flow Account";
        FromDate: Date;
        ToDate: Date;
        NoOfActualPeriods: Integer;
        I: Integer;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
    begin
        // Get available periods
        NoOfActualPeriods := GetNoOfActualPeriods();

        // Loop through available periods
        for I := 1 to NoOfActualPeriods do begin
            // Init ledger entry filters
            CFForecastEntry.Reset();
            CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
            EvaluateCFDateRangeByPeriod(I + (I div 2), FromDate, ToDate);
            CFForecastEntry.SetRange("Cash Flow Date", FromDate, ToDate);
            // Loop through all cf accounts
            CFAccount.Reset();
            CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
            CFAccount.SetRange(Blocked, false);
            if CFAccount.FindSet() then
                repeat
                    // Find all cf ledger entries linked to the current account
                    CFForecastEntry.SetRange("Cash Flow Account No.", CFAccount."No.");
                    if CFForecastEntry.FindSet() then begin
                        ExpectedAmount := 0;
                        // Loop through the cf ledger entries and sum up expected amounts
                        repeat
                            ExpectedAmount += CFForecastEntry."Amount (LCY)";
                        until CFForecastEntry.Next() = 0;
                        // Get actual value from chart data buffer based on account and period
                        ActualAmount :=
                          GetDecimalValueFromChartDataSource(BusChartBuf, Format(CFAccount."No."), I - 1);
                        // Verify amounts
                        Assert.AreEqual(ExpectedAmount, ActualAmount,
                          StrSubstNo(UnexpectedCFAmountPerAccountTypeInPeriod, Format(CFAccount."No."), I));
                    end;
                until CFAccount.Next() = 0;
        end;
    end;
}

