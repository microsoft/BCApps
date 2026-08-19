namespace System.AI;

using Microsoft.CashFlow.Setup;
using Microsoft.Foundation.Period;
using System;
using System.Globalization;
using System.Reflection;
using System.Utilities;

codeunit 2000 "Time Series Management"
{

    trigger OnRun()
    begin
    end;

    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        AzureMLConnector: Codeunit "Azure ML Connector";
        ApiUri: Text;
        ApiKey: SecretText;
        NotInitializedErr: Label 'The connection has not been initialized. Initialize the connection before using the time series functionality.';
        InitializationErr: Label 'Oops, something went wrong when connecting to the Azure Machine Learning endpoint. Please contact your system administrator.';
        TimeOutSec: Integer;
        TimeSeriesPeriodType: Option;
        TimeSeriesForecastingStartDate: Date;
        TimeSeriesObservationPeriods: Integer;
        TimeSeriesFrequency: Integer;
        TimeSeriesCalculationState: Option Uninitialized,Initialized,"Data Prepared",Done;
        DataNotPreparedErr: Label 'The data was not prepared for forecasting. Prepare data before using the forecasting functionality.';
        DataNotProcessedErr: Label 'The data for forecasting has not been processed yet. Results cannot be retrieved.';
        ForecastingPeriodsErr: Label 'The number of forecasting periods must be greater than 0.';
        MinimumHistoricalPeriods: Integer;
        NotADateErr: Label 'PeriodFieldNo must point to a Date field.';
        NotARecordErr: Label 'SourceRecord must point to Record or a RecordRef object.';
        NegativeNumberOfPeriodsErr: Label 'NumberOfPeriods Must be strictly positive.';
        MaximumHistoricalPeriods: Integer;
        TimeSeriesModelOption: Option ARIMA,ETS,STL,"ETS+ARIMA","ETS+STL",ALL;
        UseStandardCredentials: Boolean;
        ForecastSecretNameTxt: Label 'ml-forecast', Locked = true;

    [TryFunction]
    procedure Initialize(Uri: Text; "Key": SecretText; TimeOutSeconds: Integer; UseStdCredentials: Boolean)
    var
        LimitType: Option;
        Limit: Decimal;
        ApiUriSized: Text[250];
    begin
        ApiUri := Uri;
        ApiKey := Key;
        TimeOutSec := TimeOutSeconds;
        UseStandardCredentials := UseStdCredentials;

        if ((ApiUri = '') or ApiKey.IsEmpty()) and UseStdCredentials then begin
            GetMLForecastCredentials(ApiUriSized, ApiKey, LimitType, Limit);
            ApiUri := ApiUriSized;
        end;

        if not AzureMLConnector.Initialize(ApiKey, ApiUri, TimeOutSec) then
            Error(InitializationErr);

        MinimumHistoricalPeriods := 5;
        MaximumHistoricalPeriods := 24;
        TimeSeriesCalculationState := TimeSeriesCalculationState::Initialized;
    end;

    procedure InitializeFromCashFlowSetup(TimeSeriesLibState: Option Uninitialized,Initialized,"Data Prepared",Done): Boolean
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ApiUrl: Text[250];
        MLApiKey: SecretText;
        UsingStandardCredentials: Boolean;
        LimitValue: Decimal;
    begin
        if not CashFlowSetup.Get() then
            exit(false);

        CashFlowSetup.GetMLCredentials(ApiUrl, MLApiKey, LimitValue, UsingStandardCredentials);
        Initialize(ApiUrl, MLApiKey, CashFlowSetup.TimeOut, UsingStandardCredentials);
        SetMaximumHistoricalPeriods(CashFlowSetup."Historical Periods");
        GetState(TimeSeriesLibState);
        if not (TimeSeriesLibState = TimeSeriesLibState::Initialized) then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetMessageHandler(MessageHandler: DotNet HttpMessageHandler)
    begin
        AzureMLConnector.SetMessageHandler(MessageHandler);
    end;

    procedure PrepareData(RecordVariant: Variant; GroupIDFieldNo: Integer; DateFieldNo: Integer; ValueFieldNo: Integer; PeriodType: Option; ForecastingStartDate: Date; ObservationPeriods: Integer)
    begin
        if TimeSeriesCalculationState < TimeSeriesCalculationState::Initialized then
            Error(NotInitializedErr);

        TempTimeSeriesBuffer.Reset();
        TempTimeSeriesBuffer.DeleteAll();

        TimeSeriesPeriodType := PeriodType;
        TimeSeriesForecastingStartDate := ForecastingStartDate;
        TimeSeriesObservationPeriods := ObservationPeriods;
        TimeSeriesFrequency := GetFrequency(PeriodType);

        FillTimeSeriesBuffer(RecordVariant, GroupIDFieldNo, ValueFieldNo, DateFieldNo);

        TimeSeriesCalculationState := TimeSeriesCalculationState::"Data Prepared";
    end;

    procedure SetPreparedData(var TempTimeSeriesBufferIn: Record "Time Series Buffer" temporary; PeriodType: Option; ForecastingStartDate: Date; ObservationPeriods: Integer)
    begin
        if TimeSeriesCalculationState < TimeSeriesCalculationState::Initialized then
            Error(NotInitializedErr);

        TempTimeSeriesBuffer.Copy(TempTimeSeriesBufferIn, true);

        TimeSeriesPeriodType := PeriodType;
        TimeSeriesForecastingStartDate := ForecastingStartDate;
        TimeSeriesObservationPeriods := ObservationPeriods;
        TimeSeriesFrequency := GetFrequency(PeriodType);

        TimeSeriesCalculationState := TimeSeriesCalculationState::"Data Prepared";
    end;

    procedure GetPreparedData(var TempTimeSeriesBufferOut: Record "Time Series Buffer" temporary)
    begin
        if TimeSeriesCalculationState < TimeSeriesCalculationState::"Data Prepared" then
            Error(DataNotPreparedErr);

        TempTimeSeriesBufferOut.Copy(TempTimeSeriesBuffer, true);
    end;

    procedure Forecast(ForecastingPeriods: Integer; ConfidenceLevel: Integer; TimeSeriesModel: Option)
    begin
        if ConfidenceLevel = 0 then
            ConfidenceLevel := 80;
        if ForecastingPeriods < 1 then
            Error(ForecastingPeriodsErr);

        if TimeSeriesCalculationState < TimeSeriesCalculationState::"Data Prepared" then
            Error(DataNotPreparedErr);

        TempTimeSeriesForecast.Reset();
        TempTimeSeriesForecast.DeleteAll();

        if TempTimeSeriesBuffer.IsEmpty() then begin
            TimeSeriesCalculationState := TimeSeriesCalculationState::Done;
            exit;
        end;

        CreateTimeSeriesInput();
        CreateTimeSeriesParameters(ForecastingPeriods, ConfidenceLevel, TimeSeriesModel);

        if not AzureMLConnector.SendToAzureMLInternal(UseStandardCredentials) then
            Error(GetLastErrorText);

        LoadTimeSeriesForecast();
        TimeSeriesCalculationState := TimeSeriesCalculationState::Done;
    end;

    procedure GetForecast(var TempTimeSeriesForecastOut: Record "Time Series Forecast" temporary)
    begin
        if TimeSeriesCalculationState < TimeSeriesCalculationState::Done then
            Error(DataNotProcessedErr);

        TempTimeSeriesForecastOut.Copy(TempTimeSeriesForecast, true);
    end;

    procedure GetState(var State: Option Uninitialized,Initialized,"Data Prepared",Done)
    begin
        State := TimeSeriesCalculationState;
    end;

    local procedure GetFrequency(PeriodType: Option): Integer
    var
        Date: Record Date;
    begin
        case PeriodType of
            Date."Period Type"::Date:
                exit(365);
            Date."Period Type"::Week:
                exit(52);
            Date."Period Type"::Month:
                exit(12);
            Date."Period Type"::Quarter:
                exit(4);
            Date."Period Type"::Year:
                exit(1);
        end;
    end;

    procedure GetOutput(LineNo: Integer; ColumnNo: Integer): Text
    var
        OutputValue: Text;
    begin
        AzureMLConnector.GetOutput(LineNo, ColumnNo, OutputValue);
        exit(OutputValue);
    end;

    procedure GetOutputLength(): Integer
    var
        Length: Integer;
    begin
        AzureMLConnector.GetOutputLength(Length);
        exit(Length);
    end;

    procedure GetInput(LineNo: Integer; ColumnNo: Integer): Text
    var
        InputValue: Text;
    begin
        AzureMLConnector.GetInput(LineNo, ColumnNo, InputValue);
        exit(InputValue);
    end;

    procedure GetInputLength(): Integer
    var
        Length: Integer;
    begin
        AzureMLConnector.GetInputLength(Length);
        exit(Length);
    end;

    procedure GetParameter(Name: Text): Text
    var
        ParameterValue: Text;
    begin
        AzureMLConnector.GetParameter(Name, ParameterValue);
        exit(ParameterValue);
    end;

    local procedure FillTimeSeriesBuffer(RecordVariant: Variant; GroupIDFieldNo: Integer; ValueFieldNo: Integer; DateFieldNo: Integer)
    var
        TempTimeSeriesBufferDistinct: Record "Time Series Buffer" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        RecRef: RecordRef;
        GroupIDFieldRef: FieldRef;
        ValueFieldRef: FieldRef;
        DateFieldRef: FieldRef;
        CurrentPeriod: Integer;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        Value: Decimal;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecRef);

        if RecRef.IsEmpty() then
            exit;

        GroupIDFieldRef := RecRef.Field(GroupIDFieldNo);
        DateFieldRef := RecRef.Field(DateFieldNo);
        ValueFieldRef := RecRef.Field(ValueFieldNo);

        GetDistinctRecords(RecRef, GroupIDFieldNo, TempTimeSeriesBufferDistinct);

        if TempTimeSeriesBufferDistinct.FindSet() then
            repeat
                GroupIDFieldRef.SetRange(TempTimeSeriesBufferDistinct."Group ID");
                for CurrentPeriod := -TimeSeriesObservationPeriods to -1 do begin
                    PeriodStartDate :=
                      PeriodPageManagement.MoveDateByPeriod(TimeSeriesForecastingStartDate, TimeSeriesPeriodType, CurrentPeriod);
                    PeriodEndDate :=
                      PeriodPageManagement.MoveDateByPeriodToEndOfPeriod(TimeSeriesForecastingStartDate, TimeSeriesPeriodType, CurrentPeriod);
                    DateFieldRef.SetRange(PeriodStartDate, PeriodEndDate);
                    if ValueFieldRef.Class = FieldClass::Normal then
                        Value := CalculateValueNormal(ValueFieldRef)
                    else
                        Value := CalculateValueFlowField(RecRef, ValueFieldRef);
                    TempTimeSeriesBuffer.Init();
                    TempTimeSeriesBuffer."Group ID" := GroupIDFieldRef.GetFilter;
                    TempTimeSeriesBuffer."Period No." := TimeSeriesObservationPeriods + CurrentPeriod + 1;
                    TempTimeSeriesBuffer."Period Start Date" := PeriodStartDate;
                    TempTimeSeriesBuffer.Value := Value;
                    TempTimeSeriesBuffer.Insert();
                end;
            until TempTimeSeriesBufferDistinct.Next() = 0;
    end;

    local procedure CalculateValueNormal(var ValueFieldRef: FieldRef) Value: Decimal
    begin
        if ValueFieldRef.Class <> FieldClass::Normal then
            exit(0);

        ValueFieldRef.CalcSum();
        Value := ValueFieldRef.Value();
    end;

    local procedure CalculateValueFlowField(var RecRef: RecordRef; var ValueFieldRef: FieldRef) Value: Decimal
    var
        CurrentValue: Decimal;
    begin
        if ValueFieldRef.Class <> FieldClass::FlowField then
            exit(0);

        if RecRef.FindSet() then
            repeat
                ValueFieldRef.CalcField();
                CurrentValue := ValueFieldRef.Value();
                Value += CurrentValue;
            until RecRef.Next() = 0;
    end;

    local procedure CreateTimeSeriesInput()
    begin
        AzureMLConnector.AddInputColumnName('GranularityAttribute');
        AzureMLConnector.AddInputColumnName('DateKey');
        AzureMLConnector.AddInputColumnName('TransactionQty');

        if TempTimeSeriesBuffer.FindSet() then
            repeat
                AzureMLConnector.AddInputRow();
                AzureMLConnector.AddInputValue(Format(TempTimeSeriesBuffer."Group ID"));
                AzureMLConnector.AddInputValue(Format(TempTimeSeriesBuffer."Period No."));
                AzureMLConnector.AddInputValue(Format(TempTimeSeriesBuffer.Value, 0, 9));
            until TempTimeSeriesBuffer.Next() = 0;
    end;

    local procedure CreateTimeSeriesParameters(ForecastingPeriods: Integer; ConfidenceLevel: Integer; TimeSeriesModel: Option ARIMA,ETS,STL,"ETS+ARIMA","ETS+STL",ALL,TBATS)
    begin
        AzureMLConnector.AddParameter('horizon', Format(ForecastingPeriods));
        AzureMLConnector.AddParameter('seasonality', Format(TimeSeriesFrequency));
        AzureMLConnector.AddParameter('forecast_start_datekey', Format(TimeSeriesObservationPeriods + 1));
        AzureMLConnector.AddParameter('time_series_model', Format(TimeSeriesModel));
        AzureMLConnector.AddParameter('confidence_level', Format(ConfidenceLevel));
    end;

    local procedure LoadTimeSeriesForecast()
    var
        TypeHelper: Codeunit "Type Helper";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
        Value: Variant;
        LineNo: Integer;
        GroupID: Code[50];
        PeriodNo: Integer;
    begin
        for LineNo := 1 to GetOutputLength() do begin
            TempTimeSeriesForecast.Init();

            Evaluate(GroupID, GetOutput(LineNo, 1));
            TempTimeSeriesForecast."Group ID" := GroupID;

            Evaluate(PeriodNo, GetOutput(LineNo, 2));
            TempTimeSeriesForecast."Period No." := PeriodNo;
            TempTimeSeriesForecast."Period Start Date" :=
              PeriodPageManagement.MoveDateByPeriod(
                TimeSeriesForecastingStartDate, TimeSeriesPeriodType, PeriodNo - TimeSeriesObservationPeriods - 1);
            Value := TempTimeSeriesForecast.Value;
            TypeHelper.Evaluate(Value, GetOutput(LineNo, 3), '', DotNet_CultureInfo.CurrentCultureName());
            TempTimeSeriesForecast.Value := Value;

            Value := TempTimeSeriesForecast.Delta;
            TypeHelper.Evaluate(Value, GetOutput(LineNo, 4), '', DotNet_CultureInfo.CurrentCultureName());
            TempTimeSeriesForecast.Delta := Value;
            if TempTimeSeriesForecast.Value <> 0 then
                TempTimeSeriesForecast."Delta %" := Abs(TempTimeSeriesForecast.Delta / TempTimeSeriesForecast.Value) * 100;

            TempTimeSeriesForecast.Insert();
        end;
    end;

    local procedure GetDistinctRecords(RecRef: RecordRef; FieldNo: Integer; var TempTimeSeriesBufferDistinct: Record "Time Series Buffer" temporary)
    var
        FieldRef: FieldRef;
        OptionValue: Integer;
    begin
        FieldRef := RecRef.Field(FieldNo);

        if RecRef.FindSet() then
            repeat
                TempTimeSeriesBufferDistinct.Init();
                if FieldRef.Type = FieldType::Option then begin
                    OptionValue := FieldRef.Value();
                    TempTimeSeriesBufferDistinct."Group ID" := Format(OptionValue);
                end else
                    TempTimeSeriesBufferDistinct."Group ID" := FieldRef.Value();
                if not TempTimeSeriesBufferDistinct.Insert() then;
            until RecRef.Next() = 0;
    end;

    procedure SetMinimumHistoricalPeriods(NumberOfPeriods: Integer)
    begin
        if not (NumberOfPeriods > 0) then
            Error(NegativeNumberOfPeriodsErr);
        MinimumHistoricalPeriods := NumberOfPeriods;
    end;

    procedure SetMaximumHistoricalPeriods(NumberOfPeriods: Integer)
    begin
        if not (NumberOfPeriods > 0) then
            Error(NegativeNumberOfPeriodsErr);
        MaximumHistoricalPeriods := NumberOfPeriods;
    end;

    procedure HasMinimumHistoricalData(var NumberOfPeriodsWithHistory: Integer; SourceRecord: Variant; PeriodFieldNo: Integer; PeriodType: Option Day,Week,Month,Quarter,Year; ForecastStartDate: Date): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        PeriodFieldRef: FieldRef;
        HistoryStartDate: Variant;
        HistoryEndDate: Date;
    begin
        // SourceRecord Should already contain all the necessary filters
        // and should be sorted by the desired date field
        if SourceRecord.IsRecord then
            DataTypeManagement.GetRecordRef(SourceRecord, SourceRecordRef)
        else
            if SourceRecord.IsRecordRef then
                SourceRecordRef := SourceRecord
            else
                Error(NotARecordErr);

        if not SourceRecordRef.FindFirst() then
            exit(false);

        // last date of transaction history that will be used for forecast
        HistoryEndDate := CalcDate('<-1D>', ForecastStartDate);

        PeriodFieldRef := SourceRecordRef.Field(PeriodFieldNo);
        PeriodFieldRef.SetFilter('%1..', CalculateMaxStartDate(HistoryEndDate, PeriodType));
        if SourceRecordRef.FindSet() then;
        PeriodFieldRef := SourceRecordRef.Field(PeriodFieldNo);
        HistoryStartDate := PeriodFieldRef.Value();
        if not (HistoryStartDate.IsDate or HistoryStartDate.IsDateTime) then
            Error(NotADateErr);
        NumberOfPeriodsWithHistory :=
          CalculatePeriodsWithHistory(HistoryStartDate, HistoryEndDate, PeriodType);
        if NumberOfPeriodsWithHistory < MinimumHistoricalPeriods then
            exit(false);
        exit(true);
    end;

    local procedure CalculatePeriodsWithHistory(HistoryStartDate: Date; HistoryEndDate: Date; PeriodType: Option) NumberOfPeriodsWithHistory: Integer
    var
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        while HistoryStartDate <= HistoryEndDate do begin
            NumberOfPeriodsWithHistory += 1;
            HistoryStartDate := PeriodPageManagement.MoveDateByPeriod(HistoryStartDate, PeriodType, 1);
        end;
    end;

    local procedure CalculateMaxStartDate(HistoryEndDate: Date; PeriodType: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodType of
            PeriodType::Day:
                exit(CalcDate(StrSubstNo('<-%1D>', Format(MaximumHistoricalPeriods - 1)), HistoryEndDate));
            PeriodType::Week:
                exit(CalcDate(StrSubstNo('<-%1W+1D>', Format(MaximumHistoricalPeriods)), HistoryEndDate));
            PeriodType::Month:
                exit(CalcDate(StrSubstNo('<-%1M+1D>', Format(MaximumHistoricalPeriods)), HistoryEndDate));
            PeriodType::Quarter:
                exit(CalcDate(StrSubstNo('<-%1Q+1D>', Format(MaximumHistoricalPeriods)), HistoryEndDate));
            PeriodType::Year:
                exit(CalcDate(StrSubstNo('<-%1Y+1D>', Format(MaximumHistoricalPeriods)), HistoryEndDate));
        end;
    end;

    procedure GetTimeSeriesModelOption(TimeSeriesModel: Text): Integer
    begin
        Evaluate(TimeSeriesModelOption, TimeSeriesModel);
        exit(TimeSeriesModelOption);
    end;

    [NonDebuggable]
    [TryFunction]
    [Scope('OnPrem')]
    procedure GetMLForecastCredentials(var LocalApiUri: Text[250]; var "Key": SecretText; var LimitType: Option; var Limit: Decimal)
    var
        MachineLearningKeyVaultMgmt: Codeunit "Machine Learning KeyVaultMgmt.";
    begin
        MachineLearningKeyVaultMgmt.GetMachineLearningCredentials(ForecastSecretNameTxt, LocalApiUri, "Key", LimitType, Limit);
        LocalApiUri += '/execute?api-version=2.0&details=true';
    end;
}
