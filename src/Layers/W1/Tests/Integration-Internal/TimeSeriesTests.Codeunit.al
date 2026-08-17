codeunit 135200 "Time Series Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Time Series]
    end;

    var
        Assert: Codeunit Assert;
        NotInitializedErr: Label 'The connection has not been initialized. Initialize the connection before using the time series functionality.';
        DataNotPreparedErr: Label 'The data was not prepared for forecasting. Prepare data before using the forecasting functionality.';
        DataNotProcessedErr: Label 'The data for forecasting has not been processed yet. Results cannot be retrieved.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        MockServiceURITxt: Label 'https://localhost:8080/services.azureml.net/workspaces/2eaccaaec84c47c7a1f8f01ec0a6eea7', Locked = true;
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        HttpMessageHandler: DotNet MockHttpMessageHandler;
        DataSize: Option "No Data",Small,Big;
        TimeSeriesCalculationState: Option Uninitialized,Initialized,"Data Prepared",Done;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotInitilized()
    var
        TimeSeriesManagement: Codeunit "Time Series Management";
        RecordVariant: Variant;
        State: Option;
    begin
        // [SCENARIO] Error is thrown when data is prepared without the Azure ML connection having been initialized
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] The PrepareData function is called without connection having been initialized first
        asserterror TimeSeriesManagement.PrepareData(RecordVariant, 0, 0, 0, 0, 0D, 0);

        // [THEN] The state of Time Series Management is still uninitialized
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::Uninitialized, State, 'State is not uninitialized');

        // [THEN] An error is thrown: "The connection has not been initialized."
        Assert.ExpectedError(NotInitializedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataNotPrepared()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        // [SCENARIO] Error is thrown when processing of data is invoked without data having been prepared
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] The ProcessData function is called without data having been prepared
        asserterror TimeSeriesManagement.Forecast(1, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] An error is thrown: "The data was not prepared for forecasting."
        Assert.ExpectedError(DataNotPreparedErr);

        // [WHEN] The GetInputData function is called without data having been prepared
        asserterror TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);

        // [THEN] An error is thrown: "The data was not prepared for forecasting."
        Assert.ExpectedError(DataNotPreparedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataNotProcessed()
    var
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        // [SCENARIO] Error is thrown when attempting to load data without data having been processed
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] The LoadForecast function is called without data having been processed
        asserterror TimeSeriesManagement.GetForecast(TempTimeSeriesForecast);

        // [THEN] An error is thrown: "The data for forecasting has not been processed."
        Assert.ExpectedError(DataNotProcessedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDataPreparation()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        State: Option;
        Url: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] The time series buffer is filled for consumption by Azure ML

        // [GIVEN] A range of records, used for the source of the time series
        CreateTestData(ItemLedgerEntry, DataSize::Small);

        // [GIVEN] An initialized Time Series Management
        LibraryLowerPermissions.SetO365Basic();
        Url := 'https://services.azureml.net';
        ApiKey := '';
        TimeSeriesManagement.Initialize(Url, ApiKey, 0, false);

        // [WHEN] The data is prepared
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), Date."Period Type"::Month, WorkDate(), 3);

        // [THEN] The data is inserted into the time series buffer and is accessible through the GetPreparedData function
        TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);
        Assert.RecordCount(TempTimeSeriesBuffer, 3);

        // [THEN] State of Time Series Management is "Data Prepared"
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::"Data Prepared", State, 'State is not Data Prepared');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoDataToProcess()
    var
        AzureAIUsage: Record "Azure AI Usage";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Date: Record Date;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
        State: Option;
    begin
        // [SCENARIO] Forecasting is completed, even if no input data is provided

        // [GIVEN] An initialized Time Series Management
        LibraryLowerPermissions.SetO365Basic();
        AzureAIUsage.DeleteAll();
        GetForecast(TimeSeriesManagement, TempItemLedgerEntry, TempTimeSeriesForecast, Date."Period Type"::Date, 1);

        // [THEN] An empty result set is returend, since nothing could be calculated
        Assert.RecordIsEmpty(TempTimeSeriesForecast);

        // [THEN] State of Time Series Management is set to done
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::Done, State, 'State is not done');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInputPreparation()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TempTimeSeriesBufferInput: Record "Time Series Buffer" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
        LineNo: Integer;
        No: Integer;
        Quantity: Integer;
        OriginalWorkDate: Date;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] A time series input for Azure ML is created

        // [GIVEN] A range of records, used for the source of the time series
        OriginalWorkDate := WorkDate();
        WorkDate := DMY2Date(15, 3, 2019);
        CreateTestData(ItemLedgerEntry, DataSize::Big);
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] An initialized Time Series Management
        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);

        // [WHEN] The data is prepared and processed
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), Date."Period Type"::Month, WorkDate(), 12);

        WorkDate := OriginalWorkDate;
        TimeSeriesManagement.Forecast(3, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] The input contains the correct data
        for LineNo := 1 to TimeSeriesManagement.GetInputLength() do begin
            TempTimeSeriesBufferInput.Init();

            Evaluate(No, TimeSeriesManagement.GetInput(LineNo, 2));
            TempTimeSeriesBufferInput."Period No." := No;

            Evaluate(Quantity, TimeSeriesManagement.GetInput(LineNo, 3));
            TempTimeSeriesBufferInput.Value := Quantity;

            TempTimeSeriesBufferInput.Insert();
        end;

        ItemLedgerEntry.SetCurrentKey("Posting Date");
        ItemLedgerEntry.FindSet();
        TempTimeSeriesBufferInput.FindSet();

        Assert.AreEqual(ItemLedgerEntry.Count, TempTimeSeriesBufferInput.Count, 'Number of records differ.');

        repeat
            Assert.AreEqual(ItemLedgerEntry.Quantity, TempTimeSeriesBufferInput.Value,
              'Quantity in Azure ML input differs from quantity in ledger entries');
            TempTimeSeriesBufferInput.Next();
        until ItemLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestParametersCreation()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        Horizon: Integer;
        StartDateKey: Integer;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] Time Series parameters are set correctly, when processing is run

        // [GIVEN] A range of records, used for the source of the time series
        CreateTestData(ItemLedgerEntry, DataSize::Small);

        // [GIVEN] An initialized Time Series Management
        LibraryLowerPermissions.SetO365Basic();
        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);

        // [GIVEN] The data has been prepared
        StartDateKey := 4; // Starting 3 months back with a frequency of a month
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), Date."Period Type"::Month, WorkDate(), 3);

        // [WHEN] The time series processing has completed
        Horizon := 3;
        TimeSeriesManagement.Forecast(Horizon, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] The parameters contain the horizon, frequency, forecast start datekey as well as time series model
        Assert.AreEqual(
          Format(Horizon), TimeSeriesManagement.GetParameter('horizon'),
          'The Horizon is set incorrectly.'); // Horizon
        Assert.AreEqual(
          Format(ConvertFrequency(Date."Period Type"::Month)), TimeSeriesManagement.GetParameter('seasonality'),
          'The Frequency is set incorrectly.'); // Frequency
        Assert.AreEqual(
          Format(StartDateKey), TimeSeriesManagement.GetParameter('forecast_start_datekey'),
          'The Forecast Start Datekey is set incorrectly.'); // Forecast Start Datekey
        Assert.AreEqual('ARIMA', TimeSeriesManagement.GetParameter('time_series_model'), 'The Time Series Model is set incorrectly.'); // Time Series Model
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForecastingOnNormalFields()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        State: Option;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] Time Series Forecast output is created, when data based on normal fields has been processed

        // [GIVEN] A range of records, used for the source of the time series
        CreateTestData(ItemLedgerEntry, DataSize::Big);

        // [GIVEN] An initialized Time Series Management
        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] The data with normal fields has been prepared
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), Date."Period Type"::Quarter, WorkDate(), 4);

        // [WHEN] The time series processing has completed
        TimeSeriesManagement.Forecast(6, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] A time series forecast is created
        Assert.IsTrue(TimeSeriesManagement.GetOutputLength() > 0, 'The forecast was not created.');

        // [THEN] State of Time Series Management is set to done
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::Done, State, 'State is not done');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForecastingOnFlowfields()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        State: Option;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] A Time Series Forecast output is created, when data based on flowfields has been processed

        // [GIVEN] An initialized Time Series Management
        LibraryLowerPermissions.SetSalesDocsCreate();

        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);

        // [GIVEN] The data with flowfields has been prepared
        TimeSeriesManagement.PrepareData(
          CustLedgerEntry, CustLedgerEntry.FieldNo("Customer No."), CustLedgerEntry.FieldNo("Posting Date"),
          CustLedgerEntry.FieldNo(Amount), Date."Period Type"::Quarter, WorkDate(), 4);

        // [WHEN] The time series processing has completed
        TimeSeriesManagement.Forecast(6, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] A time series forecast is created
        Assert.IsTrue(TimeSeriesManagement.GetOutputLength() > 0, 'The forecast was not created.');

        // [THEN] State of Time Series Management is set to done
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::Done, State, 'State is not done');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestForecastingOnManuallyEnteredData()
    var
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        State: Option;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] A Time Series Forecast output is created, when manually created data has been processed

        // [GIVEN] An initialized Time Series Management
        LibraryLowerPermissions.SetO365Basic();

        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);

        // [GIVEN] The data has been prepared
        TempTimeSeriesBuffer.Init();
        TempTimeSeriesBuffer."Group ID" := 'DEFAULT';
        TempTimeSeriesBuffer."Period No." := 1;
        TempTimeSeriesBuffer."Period Start Date" := WorkDate();
        TempTimeSeriesBuffer.Value := 1;
        TempTimeSeriesBuffer.Insert();

        TimeSeriesManagement.SetPreparedData(TempTimeSeriesBuffer, Date."Period Type"::Quarter, WorkDate(), 1);

        // [WHEN] The time series processing has completed
        TimeSeriesManagement.Forecast(1, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));

        // [THEN] A time series forecast is created
        Assert.IsTrue(TimeSeriesManagement.GetOutputLength() > 0, 'The forecast was not created.');

        // [THEN] State of Time Series Management is set to done
        TimeSeriesManagement.GetState(State);
        Assert.AreEqual(TimeSeriesCalculationState::Done, State, 'State is not done');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResultsConversionFromCSVtoRecords()
    var
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        // [SCENARIO] Time Series Forecast records are created based on a Time Series Forecast CSV file

        // [GIVEN] A completed time series forecast scenario
        CreateTestData(ItemLedgerEntry, DataSize::Small);
        LibraryLowerPermissions.SetO365Basic();
        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));

        // [WHEN] The results are requested
        GetForecast(TimeSeriesManagement, ItemLedgerEntry, TempTimeSeriesForecast, Date."Period Type"::Month, 3);

        // [THEN] The results are provided as records in the Time Series Forecast table
        Assert.RecordCount(TempTimeSeriesForecast, 12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodStartDateOnTimeSeries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TimeSeriesManagement: Codeunit "Time Series Management";
        ExpectedDate: Date;
        ObservationPeriods: Integer;
        ForecastPeriods: Integer;
        CurrentPeriod: Integer;
        ApiUrl: Text;
        ApiKey: Text;
    begin
        // [SCENARIO] The dates in the Time Series Buffer table have the correct values

        // [GIVEN] Data has been prepared
        CreateTestData(ItemLedgerEntry, DataSize::Big);
        LibraryLowerPermissions.SetO365Basic();
        TimeSeriesManagement.SetMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(LibraryUtilityOnPrem.GetInetRoot() + GetResponseFileName()));
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);
        ObservationPeriods := 24; // The oberservation period in the mock service is 24.
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), Date."Period Type"::Month, WorkDate(), ObservationPeriods);

        // [WHEN] The records are retrieved
        TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);

        // [THEN] The dates in the Time Series Buffer are calculated correctly
        TempTimeSeriesBuffer.FindSet();
        repeat
            CurrentPeriod := ObservationPeriods - TempTimeSeriesBuffer."Period No." + 1;
            ExpectedDate := CalcDate('<-' + Format(CurrentPeriod) + 'M>', WorkDate());
            Assert.AreEqual(ExpectedDate, TempTimeSeriesBuffer."Period Start Date", 'The date is incorrect');
        until TempTimeSeriesBuffer.Next() = 0;

        // [WHEN] The the forecast is executed and retrieved
        ForecastPeriods := 6;
        TimeSeriesManagement.Forecast(ForecastPeriods, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast);

        // [THEN] The dates in the Time Series Forecast are calculated correctly
        TempTimeSeriesForecast.FindSet();
        repeat
            CurrentPeriod := TempTimeSeriesForecast."Period No." - ObservationPeriods - 1;
            ExpectedDate := CalcDate('<' + Format(CurrentPeriod) + 'M>', WorkDate());
            Assert.AreEqual(ExpectedDate, TempTimeSeriesForecast."Period Start Date", 'The date is incorrect');
        until TempTimeSeriesForecast.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasMinimumHistoricalData()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Date: Record Date;
        TimeSeriesManagement: Codeunit "Time Series Management";
        ItemLedgerEntryRecordRef: RecordRef;
        NumberOfPeriodsWithHistory: Integer;
    begin
        // [SCENARIO] Retrieve the number of periods with history

        // [GIVEN] A code Field is given as a period Field
        // [THEN] An ERROR is raised
        asserterror TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            ItemLedgerEntry,
            ItemLedgerEntry.FieldNo("Item No."),
            Date."Period Type"::Month,
            WorkDate());

        // [GIVEN] An integer is given instead of a record
        // [THEN] An ERROR is raised
        asserterror TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            NumberOfPeriodsWithHistory,
            ItemLedgerEntry.FieldNo("Posting Date"),
            Date."Period Type"::Month,
            WorkDate());

        // [GIVEN] There are historical data for 12 months
        CreateTestData(ItemLedgerEntry, DataSize::Big);
        ItemLedgerEntry.SetCurrentKey("Posting Date");
        ItemLedgerEntryRecordRef.GetTable(ItemLedgerEntry);
        // [GIVEN] Thee minimum number of historical periods is 5
        TimeSeriesManagement.SetMinimumHistoricalPeriods(5);

        LibraryLowerPermissions.SetO365Basic();

        // [THEN] There are 12 periods with history when period type is month (RecordRef)
        Assert.IsTrue(TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            ItemLedgerEntryRecordRef,
            ItemLedgerEntryRecordRef.FieldIndex(ItemLedgerEntry.FieldNo("Posting Date")).Number,
            Date."Period Type"::Month, WorkDate()), 'It should have at least 5 months of historical data.');
        Assert.AreEqual(NumberOfPeriodsWithHistory, 12, 'It should have 12 months of historical data.');

        // [THEN] There are 12 periods with history when period type is month (Record)
        Assert.IsTrue(TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            ItemLedgerEntry,
            ItemLedgerEntry.FieldNo("Posting Date"),
            Date."Period Type"::Month, WorkDate()), 'It should have at least 5 months of historical data.');
        Assert.AreEqual(NumberOfPeriodsWithHistory, 12, 'It should have 12 months of historical data.');

        // [THEN] There is 1 period with history when period type is year
        Assert.IsFalse(TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            ItemLedgerEntry,
            ItemLedgerEntry.FieldNo("Posting Date"),
            Date."Period Type"::Year, WorkDate()), 'It should not have 5 years of historical data.');
        Assert.AreEqual(NumberOfPeriodsWithHistory, 1, 'It should have 1 year of historical data.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetMinimumHistoricalPeriods()
    var
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        // [SCENARIO] Developers may setup their desired number of minimum historical periods
        // [GIVEN] The Minimum historical periods is set to Negative
        // [THEN] An ERROR is raised
        LibraryLowerPermissions.SetO365Basic();
        asserterror TimeSeriesManagement.SetMinimumHistoricalPeriods(-5);
        TimeSeriesManagement.SetMinimumHistoricalPeriods(5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetMaximumHistoricalPeriods()
    var
        TimeSeriesManagement: Codeunit "Time Series Management";
    begin
        // [SCENARIO] Developers may setup their desired number of Maximum historical periods
        // [GIVEN] The Maximum historical periods is set to Negative
        // [THEN] An ERROR is raised
        LibraryLowerPermissions.SetO365Basic();
        asserterror TimeSeriesManagement.SetMaximumHistoricalPeriods(-5);
        TimeSeriesManagement.SetMaximumHistoricalPeriods(5);
    end;

    local procedure CreateTestData(var ItemLedgerEntry: Record "Item Ledger Entry"; LedgerDataSize: Option "No Data",Small,Big)
    var
        Item: Record Item;
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateItem(Item);
        CreateCustomer(Customer);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        CreateLedgerEntries(Item, Customer, LedgerDataSize);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    [Scope('OnPrem')]
    procedure CreateLedgerEntries(var Item: Record Item; var Customer: Record Customer; LedgerDataSize: Option "No Data",Small,Big)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        OriginalWorkDate: Date;
        "count": Integer;
    begin
        if LedgerDataSize = LedgerDataSize::"No Data" then
            exit;

        OriginalWorkDate := WorkDate();
        WorkDate := CalcDate('<-1D>', WorkDate());

        for count := 1 to 12 do begin
            LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
              Customer."No.", Item."No.", 5 * count, '', WorkDate());
            LibrarySales.PostSalesDocument(SalesHeader, true, true);

            if (LedgerDataSize = LedgerDataSize::Small) and (count = 3) then begin
                WorkDate := OriginalWorkDate;
                exit;
            end;

            WorkDate := CalcDate('<-1M>', WorkDate());
        end;

        WorkDate := OriginalWorkDate;
    end;

    local procedure ConvertFrequency(PeriodType: Option): Integer
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

    local procedure GetResponseFileName(): Text[80]
    begin
        exit('\App\Test\Files\AzureMLResponse\Time_Series_Forecast.txt');
    end;

    [Normal]
    local procedure GetForecast(var TimeSeriesManagement: Codeunit "Time Series Management"; var ItemLedgerEntry: Record "Item Ledger Entry"; var TempTimeSeriesForecast: Record "Time Series Forecast" temporary; PeriodType: Option; Periods: Integer)
    var
        ApiUrl: Text;
        ApiKey: Text;
    begin
        ApiUrl := MockServiceURITxt;
        ApiKey := '';
        TimeSeriesManagement.Initialize(ApiUrl, ApiKey, 0, false);
        TimeSeriesManagement.PrepareData(
          ItemLedgerEntry, ItemLedgerEntry.FieldNo("Item No."), ItemLedgerEntry.FieldNo("Posting Date"),
          ItemLedgerEntry.FieldNo(Quantity), PeriodType, WorkDate(), Periods);
        TimeSeriesManagement.Forecast(Periods, 80, TimeSeriesManagement.GetTimeSeriesModelOption('ARIMA'));
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast)
    end;
}
