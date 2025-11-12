namespace System.Visualization;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Integration;
using System.Utilities;

table 485 "Business Chart Buffer"
{
    Caption = 'Business Chart Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Chart Type"; Enum "Business Chart Type")
        {
            Caption = 'Chart Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Data Type"; Option)
        {
            Caption = 'Data Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'String,Integer,Decimal,DateTime';
            OptionMembers = String,"Integer",Decimal,DateTime;
        }
        field(5; "Drill-Down X Index"; Integer)
        {
            Caption = 'Drill-Down X Index';
            DataClassification = SystemMetadata;
        }
        field(6; "Drill-Down Y Value"; Decimal)
        {
            Caption = 'Drill-Down Y Value';
            DataClassification = SystemMetadata;
        }
        field(7; "Drill-Down Measure Index"; Integer)
        {
            Caption = 'Drill-Down Measure Index';
            DataClassification = SystemMetadata;
        }
        field(8; "Period Length"; Option)
        {
            Caption = 'Period Length';
            DataClassification = SystemMetadata;
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period,None';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period","None";
        }
        field(9; "Period Filter Start Date"; Date)
        {
            Caption = 'Period Filter Start Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Period Filter End Date"; Date)
        {
            Caption = 'Period Filter End Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Error(CannotInsertErr, TableCaption);
    end;

    var
        TempBusChartMapToColumn: Record "Business Chart Map" temporary;
        BusinessChart: Codeunit "Business Chart";
        CurrentMeasure: Integer;
#pragma warning disable AA0470
        CannotInsertErr: Label 'You cannot insert into table %1.';
        MeasureLimitErr: Label 'You cannot add more than %1 measures.';
#pragma warning restore AA0470

    local procedure GetDataType(Type: Option): Enum "Business Chart Data Type"
    begin
        case Type of
            "Data Type"::DateTime:
                exit(Enum::"Business Chart Data Type"::DateTime);
            "Data Type"::Decimal:
                exit(Enum::"Business Chart Data Type"::Decimal);
            "Data Type"::Integer:
                exit(Enum::"Business Chart Data Type"::Integer);
            "Data Type"::String:
                exit(Enum::"Business Chart Data Type"::String);
        end;
    end;

    procedure Initialize()
    begin
        BusinessChart.Initialize();
        TempBusChartMapToColumn.Reset();
        TempBusChartMapToColumn.DeleteAll();
    end;

    procedure SetChartCondensed(Condensed: Boolean)
    begin
        BusinessChart.SetShowChartCondensed(Condensed);
    end;

    procedure SetXAxis(Caption: Text; Type: Option)
    begin
        BusinessChart.SetXDimension(Caption, GetDataType(Type));
    end;

    procedure SetPeriodXAxis()
    var
        DataType: Enum "Business Chart Data Type";
    begin
        if "Period Length" = "Period Length"::Day then
            DataType := DataType::DateTime
        else
            DataType := DataType::String;
        BusinessChart.SetXDimension(Format("Period Length"), DataType);
    end;

    procedure GetXCaption(): Text
    begin
        exit(BusinessChart.GetXDimension());
    end;

    procedure AddMeasure(Caption: Text; Value: Variant; ValueType: Option; ChartType: Integer)
    begin
        "Data Type" := ValueType;
        BusinessChart.AddMeasure(Caption, Value, GetDataType(ValueType), Enum::"Business Chart Type".FromInteger(ChartType));
    end;

    procedure AddDecimalMeasure(Caption: Text; Value: Variant; ChartType: Enum "Business Chart Type")
    begin
        "Data Type" := "Data Type"::Decimal;
        BusinessChart.AddMeasure(Caption, Value, Enum::"Business Chart Data Type"::Decimal, ChartType);
    end;

    procedure AddIntegerMeasure(Caption: Text; Value: Variant; ChartType: Enum "Business Chart Type")
    begin
        "Data Type" := "Data Type"::Integer;
        BusinessChart.AddMeasure(Caption, Value, Enum::"Business Chart Data Type"::Integer, ChartType);
    end;

    procedure GetMaxNumberOfMeasures(): Integer
    begin
        exit(BusinessChart.GetMaxNumberOfMeasures());
    end;

    procedure RaiseErrorMaxNumberOfMeasuresExceeded()
    begin
        Error(MeasureLimitErr, GetMaxNumberOfMeasures());
    end;

    procedure AddColumn(Value: Variant)
    var
        Caption: Text;
    begin
        ConvertDateToDateTime(Value);
        Caption := Format(Value, 0, 9);
        AddColumnWithCaption(Value, Caption);
    end;

    procedure AddPeriods(FromDate: Date; ToDate: Date)
    var
        ColumnNo: Integer;
        NumberOfPeriods: Integer;
    begin
        NumberOfPeriods := CalcNumberOfPeriods(FromDate, ToDate);
        for ColumnNo := 1 to NumberOfPeriods do begin
            ToDate := CalcToDate(FromDate);
            AddPeriodColumn(ToDate);
            FromDate := CalcDate('<1D>', ToDate);
        end;
    end;

    procedure AddPeriodColumn(Value: Variant)
    var
        Caption: Text;
    begin
        ConvertDateToDateTime(Value);
        Caption := GetPeriodCaption(Value);
        if "Period Length" = "Period Length"::Day then
            AddColumnWithCaption(Value, Format(Value, 0, 9))
        else
            AddColumnWithCaption(Value, Caption);
    end;

    protected procedure AddColumnWithCaption(Value: Variant; Caption: Text)
    begin
        BusinessChart.AddDataRowWithXDimension(Caption);
        TempBusChartMapToColumn.Add(Caption, Value);
    end;

    local procedure ConvertDateToDateTime(var Value: Variant)
    begin
        if IsXAxisDateTime() and Value.IsDate then
            Value := CreateDateTime(Value, 120000T);
    end;

    protected procedure AddDataColumn(Caption: Text; ValueType: Option)
    begin
        BusinessChart.AddDataColumn(Caption, GetDataType(ValueType));
    end;

    procedure SetValue(MeasureName: Text; XAxisIndex: Integer; Value: Variant)
    begin
        BusinessChart.SetValue(MeasureName, XAxisIndex, Value);
    end;

    procedure SetValueByIndex(MeasureIndex: Integer; XAxisIndex: Integer; Value: Variant)
    begin
        BusinessChart.SetValue(MeasureIndex, XAxisIndex, Value);
    end;

    procedure FindFirstMeasure(var BusChartMap: Record "Business Chart Map") Result: Boolean
    var
        Name: Text;
        ValueString: Text;
    begin
        if BusinessChart.GetMeasureNameToValueMap().Keys().Count() = 0 then
            exit(false);

        CurrentMeasure := 0;
        BusChartMap.Index := 0;
        Name := BusinessChart.GetMeasureNameToValueMap().Keys().Get(1);
        ValueString := BusinessChart.GetMeasureNameToValueMap().Values().Get(1);
        BusChartMap.Name := CopyStr(Name, 1, MaxStrLen(BusChartMap.Name));
        BusChartMap."Value String" := CopyStr(ValueString, 1, MaxStrLen(BusChartMap."Value String"));
        exit(true);
    end;

    procedure NextMeasure(var BusChartMap: Record "Business Chart Map") Result: Boolean
    var
        Name: Text;
        ValueString: Text;
    begin
        CurrentMeasure += 1;
        Result := BusinessChart.GetMeasureNameToValueMap().Count() > CurrentMeasure;
        if Result then begin
            BusChartMap.Index := CurrentMeasure;
            Name := BusinessChart.GetMeasureNameToValueMap().Keys().Get(CurrentMeasure + 1);
            ValueString := BusinessChart.GetMeasureNameToValueMap().Values().Get(CurrentMeasure + 1);
            BusChartMap.Name := CopyStr(Name, 1, MaxStrLen(BusChartMap.Name));
            BusChartMap."Value String" := CopyStr(ValueString, 1, MaxStrLen(BusChartMap."Value String"));
        end
    end;

    procedure FindFirstColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        TempBusChartMapToColumn.Reset();
        Result := TempBusChartMapToColumn.FindSet();
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure FindMidColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    var
        MidColumnIndex: Integer;
    begin
        TempBusChartMapToColumn.Reset();
        TempBusChartMapToColumn.FindLast();
        MidColumnIndex := -Round(TempBusChartMapToColumn.Count div 2);
        Result := MidColumnIndex = TempBusChartMapToColumn.Next(MidColumnIndex);
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure NextColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        Result := TempBusChartMapToColumn.Next() <> 0;
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure GetValue(MeasureName: Text; XAxisIndex: Integer; var Value: Variant)
    begin
        BusinessChart.GetValue(MeasureName, XAxisIndex, Value);
    end;

    procedure GetXValue(XAxisIndex: Integer; var Value: Variant)
    begin
        GetValue(GetXCaption(), XAxisIndex, Value);
    end;

    procedure GetXValueAsDate(XIndex: Integer): Date
    var
        Value: Variant;
    begin
        if IsXAxisDateTime() then begin
            GetXValue(XIndex, Value);
            exit(Variant2Date(Value));
        end;
        TempBusChartMapToColumn.Get(XIndex);
        exit(TempBusChartMapToColumn.GetValueAsDate());
    end;

    procedure GetMeasureValueString(MeasureIndex: Integer): Text
    var
        MeasureValues: List of [Text];
    begin
        MeasureValues := BusinessChart.GetMeasureNameToValueMap().Values();
        exit(MeasureValues.Get(MeasureIndex + 1));
    end;

    procedure GetMeasureName(MeasureIndex: Integer): Text
    var
        MeasureNames: List of [Text];
    begin
        MeasureNames := BusinessChart.GetMeasureNameToValueMap().Keys();
        exit(MeasureNames.Get(MeasureIndex + 1));
    end;

    procedure GetCurrMeasureValueString(): Text
    var
        MeasureValues: List of [Text];
    begin
        MeasureValues := BusinessChart.GetMeasureNameToValueMap().Values();
        exit(MeasureValues.Get("Drill-Down Measure Index" + 1));
    end;


    procedure UpdateChart(BusinessChartAddIn: ControlAddIn BusinessChart)
    begin
        BusinessChart.Update(BusinessChartAddIn);
    end;


    procedure SetDrillDownIndexes(Point: JsonObject)
    var
        MeasuresTok: Label 'Measures', Locked = true;
        XValueStringTok: Label 'XValueString', Locked = true;
        YValuesTok: Label 'YValues', Locked = true;
        Token: JsonToken;
        ValueArray: JsonArray;
        MeasureName: Text[249];
        XValueString: Text[249];
        YValue: Decimal;
    begin
        Point.Get(MeasuresTok, Token);
        ValueArray := Token.AsArray();
        ValueArray.Get(0, Token);
        MeasureName := CopyStr(Token.AsValue().AsText(), 1, 249);

        Point.Get(XValueStringTok, Token);
        XValueString := CopyStr(Token.AsValue().AsText(), 1, 249);

        Point.Get(YValuesTok, Token);
        ValueArray := Token.AsArray();
        ValueArray.Get(0, Token);
        YValue := Token.AsValue().AsDecimal();

        SetDrillDownIndexesByCoordinate(MeasureName, XValueString, YValue);
    end;

    local procedure GetDateString(XValueString: Text[249]): Text[249]
    var
        Days: Decimal;
        DateTime: DateTime;
    begin
        if Evaluate(Days, XValueString, 9) then begin
            DateTime := CreateDateTime(DMY2Date(30, 12, 1899) + Round(Days, 1, '<'), 120000T);
            exit(Format(DateTime, 0, 9));
        end;
        exit(XValueString);
    end;

    procedure IsXAxisDateTime(): Boolean
    begin
        exit(BusinessChart.GetXDimensionDataType() = Enum::"Business Chart Data Type"::DateTime)
    end;

    procedure CalcFromDate(Date: Date): Date
    begin
        exit(CalcPeriodDate(Date, true));
    end;

    procedure CalcToDate(Date: Date): Date
    begin
        exit(CalcPeriodDate(Date, false));
    end;

    local procedure CalcPeriodDate(Date: Date; CalcStartDate: Boolean): Date
    var
        Modificator: Text[1];
    begin
        if Date = 0D then
            exit(Date);

        case "Period Length" of
            "Period Length"::Day:
                exit(Date);
            "Period Length"::Week,
            "Period Length"::Month,
            "Period Length"::Quarter,
            "Period Length"::Year:
                begin
                    if CalcStartDate then
                        Modificator := '-';
                    exit(CalcDate(StrSubstNo('<%1C%2>', Modificator, GetPeriodLength()), Date));
                end;
        end;
    end;

    procedure CalcNumberOfPeriods(FromDate: Date; ToDate: Date): Integer
    var
        NumberOfPeriods: Integer;
    begin
        if FromDate = ToDate then
            exit(1);
        if ToDate < FromDate then
            SwapDates(FromDate, ToDate);

        case "Period Length" of
            "Period Length"::Day:
                NumberOfPeriods := ToDate - FromDate;
            "Period Length"::Week:
                NumberOfPeriods := (CalcDate('<-CW>', ToDate) - CalcDate('<-CW>', FromDate)) div 7;
            "Period Length"::Month:
                NumberOfPeriods := Date2DMY(ToDate, 2) - Date2DMY(FromDate, 2) + GetNumberOfYears(FromDate, ToDate) * 12;
            "Period Length"::Quarter:
                NumberOfPeriods := GetQuarterIndex(ToDate) - GetQuarterIndex(FromDate) + GetNumberOfYears(FromDate, ToDate) * 4;
            "Period Length"::Year:
                NumberOfPeriods := GetNumberOfYears(FromDate, ToDate);
        end;
        exit(NumberOfPeriods + 1);
    end;

    local procedure SwapDates(var FromDate: Date; var ToDate: Date)
    var
        Date: Date;
    begin
        Date := FromDate;
        FromDate := ToDate;
        ToDate := Date;
    end;

    local procedure GetNumberOfYears(FromDate: Date; ToDate: Date): Integer
    begin
        exit(Date2DMY(ToDate, 3) - Date2DMY(FromDate, 3));
    end;

    local procedure GetQuarterIndex(Date: Date): Integer
    begin
        exit((Date2DMY(Date, 2) - 1) div 3 + 1);
    end;

    procedure GetPeriodLength(): Text[1]
    begin
        case "Period Length" of
            "Period Length"::Day:
                exit('D');
            "Period Length"::Week:
                exit('W');
            "Period Length"::Month:
                exit('M');
            "Period Length"::Quarter:
                exit('Q');
            "Period Length"::Year:
                exit('Y');
        end;
    end;

    procedure GetPeriodCaption(Date: Variant): Text
    var
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Date.IsDateTime or Date.IsDate then
            exit(PeriodPageManagement.CreatePeriodFormat(Enum::"Analysis Period Type".FromInteger("Period Length"), Date));
        exit(Format(Date, 0, 9));
    end;

    procedure GetPeriodFromMapColumn(ColumnIndex: Integer; var FromDate: Date; var ToDate: Date)
    begin
        ToDate := GetXValueAsDate(ColumnIndex);
        FromDate := CalcFromDate(ToDate);
    end;

    procedure InitializePeriodFilter(StartDate: Date; EndDate: Date)
    begin
        "Period Filter Start Date" := StartDate;
        "Period Filter End Date" := EndDate;
    end;

    procedure RecalculatePeriodFilter(var StartDate: Date; var EndDate: Date; MovePeriod: Option " ",Next,Previous)
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        SearchText: Text[3];
    begin
        if StartDate <> 0D then begin
            Calendar.SetFilter("Period Start", '%1..%2', StartDate, EndDate);
            if not PeriodPageMgt.FindDate('+', Calendar, Enum::"Analysis Period Type".FromInteger("Period Length")) then
                PeriodPageMgt.FindDate('+', Calendar, Enum::"Analysis Period Type"::Day);
            Calendar.SetRange("Period Start");
        end;

        case MovePeriod of
            MovePeriod::Next:
                SearchText := '>=';
            MovePeriod::Previous:
                SearchText := '<=';
            else
                SearchText := '';
        end;

        PeriodPageMgt.FindDate(SearchText, Calendar, Enum::"Analysis Period Type".FromInteger("Period Length"));

        StartDate := Calendar."Period Start";
        EndDate := Calendar."Period End";
    end;

    procedure SetDrillDownIndexesByCoordinate(MeasureName: Text[249]; XValueString: Text[249]; YValue: Decimal)
    begin
        "Drill-Down Measure Index" := BusinessChart.GetMeasureNameToValueMap().Keys().IndexOf(MeasureName) - 1;

        if IsXAxisDateTime() then
            XValueString := GetDateString(XValueString);

        "Drill-Down X Index" := TempBusChartMapToColumn.GetIndex(XValueString);
        "Drill-Down Y Value" := YValue;
    end;
}