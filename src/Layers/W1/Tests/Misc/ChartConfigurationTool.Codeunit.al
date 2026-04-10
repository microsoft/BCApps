codeunit 136149 "Chart Configuration Tool"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Chart]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        SourceIDToSet: Integer;
        SourceTypeToSet: Integer;
        ActualFieldsListCount: Integer;
        DimensionNameToSet: Text[80];
        ActualTypeFilter: Text;
        SourceIDValidationError: Label 'There is no AllObjWithCaption within the filter.\\Filters: Object Type: %1, Object ID: %2', Comment = '%1=object type, %2=integer number';
        InvalidFilterFieldError: Label 'There is no Field within the filter.\\Filters: TableNo: %1, FieldName: %2';
        DimensionMeasureInvalidError: Label 'There is no Field within the filter.\\Filters: TableNo: %1, FieldName: %3, Type: %2, Class: %4';
        DefaultChartDescription: Label 'This is a test description for the chart';
        NothingInsideTheFilter: Label 'DB:NothingInsideFilter';
        MaxNoOfMeasures: Label 'You cannot select more than %1 measures when using the Customize Chart option.';
        TableSalesheader: Label 'Sales Header';
        DimensionMeasureInvalidErrorType0: Label 'There is no Field within the filter.\\Filters: TableNo: %1, FieldName: %2, Class: %3';
        Text000: Label 'NONE', Comment = 'NONE';
        Text001: Label 'COUNT', Comment = 'COUNT';
        Text002: Label 'SUM', Comment = 'SUM';
        Text003: Label 'MIN', Comment = 'MIN';
        Text004: Label 'MAX', Comment = 'MAX';
        Text005: Label 'AVERAGE', Comment = 'AVERAGE';
        RequiredMeasureCaptionTxt: Label 'Required Measure Caption';
        RequiredMeasureCaptionChangedTxt: Label 'Required Measure Caption Changed';
        XAxisTitleTxt: Label 'Cities';
        YAxisTitleTxt: Label 'Balances';
        ChartNotFoundErr: Label 'The Chart %1 was not found.';
        NoDataInBlobErr: Label 'The blob field does not contain any data.';
        DescriptionTxt: Label 'This chart shows information about the customer balance by City. The text can be up very very long. 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789';
        TestNameRequiredMeasureCaptionTxt: Label 'Test: Required Caption';
        TestNameEditorLanguageFieldTxt: Label 'Test: Language Field';
        TestNameEditorTextFieldTxt: Label 'Test: Text Field';
        DANLanguageCodeTxt: Label 'DAN';
        DANLanguageMemoTxt: Label 'Danish';
        ENULanguageCodeTxt: Label 'ENU';
        ENULanguageMemoTxt: Label 'English';
        LTHLanguageCodeTxt: Label 'LTH';
        LTHLanguageMemoTxt: Label 'Lithuanian';
        MemoTxt: Label 'Memo';
        LanguageCode1Txt: Label 'DAN';
        LanguageCode1AlternativeTxt: Label 'ELL';
        LanguageCode2Txt: Label 'THA';
        LanguageCode2AlternativeTxt: Label 'BGR';
        LanguageCode3Txt: Label 'KOR';
        LanguageCode3AlternativeTxt: Label 'LTH';
        LanguageNotDefinedErr: Label 'Only %1 languages are supported';
        TestNameRequiredMeasureLanguageCountTxt: Label 'Test: Required measure language count';
        ChartSetupNotShowingExpectedRecordTxt: Label 'The ChartSetup page is not open on the expected record.';
        ChartFoundInDBErr: Label 'There is an entry in the database with the same ID. A test likely did not clean-up correctly';
        TextChartNameTestTxt: Label 'Name';
        TestNameXAxisTxt: Label 'Test: X-Axis';
        TestNameShowXAxisTitleTxt: Label 'Test: Show X-Axis title';
        TestNameXAxisTitleTxt: Label 'Test: X-Axis title';
        TestNameShowYAxisTitleTxt: Label 'Test: Show Y-Axis title';
        TestNameYAxisTitleTxt: Label 'Test: Y-Axis title';
        TestNameHasTableTxt: Label 'Test: HasTable';
        TestNameTableIDTxt: Label 'Test: TableID';
        TestNameRequiredMeasureColumnTxt: Label 'Test: Required Column';
        TestNameRequiredMeasureAggregationTxt: Label 'Test: Required Aggregation';
        TestNameRequiredMeasureTypeTxt: Label 'Test: Required Type';
        TextMemoToBeTruncatedMsg: Label 'The length of the text that you entered is %1. The maximum length is %2. The text has been truncated to this length.';
        MemoTestNameTxt: Label 'Test: Memo message';
        XAxisDatapointTxt: Label 'X Data Point';
        TestNameXAxisDatapointTxt: Label 'Test: X axis Datapoint';
        ColumnDataTypeErr: Label 'Wrong column data dype ';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Chart Configuration Tool");
        ClearGlobals();
    end;

    [Scope('OnPrem')]
    procedure TestQueryChart2DimensionsRequiredMeasure()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary;
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        DataMeasureType: DotNet DataMeasureType;
        DataAggregationType: DotNet DataAggregationType;
        ChartBuilder: DotNet BusinessChartBuilder;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        HasXDimension: Boolean;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        HasZDimension: Boolean;
        ZDimensionID: Integer;
        ZDimensionName: Text[250];
        ShowZDimensionTitle: Boolean;
        CountOfMeasures: Integer;
        MeasureIndex: Integer;
        MeasureID: Integer;
        MeasureName: Text[50];
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        FilterCount: Integer;
        ChartCode: Code[20];
        RetrievedDescription: Text;
    begin
        // [GIVEN] Create a query based chart
        Initialize();
        GetDefaultSourceQueryInfo(SourceName, SourceID, SourceType);
        CountOfMeasures := 1;

        // Y Axis
        MeasureIndex := 0;
        DataMeasureType := DataMeasureType.Line;
        GetDefaultMeasureInfoForQuery(DataAggregationType, MeasureID, MeasureName);

        // X Axis
        HasXDimension := true;
        GetDefaultXDimensionInfoForQuery(XDimensionID, XDimensionName, ShowXDimensionTitle);

        // Z Axis
        HasZDimension := false;
        ZDimensionID := 0;
        ZDimensionName := '';
        ShowZDimensionTitle := false;

        // FILTERS
        FilterCount := 1;
        FilterIndex := 0;
        GetDefaultFilterInfoForQuery(FilterFieldName, FilterFieldValue, FilterFieldId);

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        SourceIDToSet := SourceID;
        DimensionNameToSet := XDimensionName;

        GenericChartMgt.RetrieveFieldColumn(
          TempGenericChartSetup,
          TempGenericChartSetup."X-Axis Field ID",
          TempGenericChartSetup."X-Axis Field Name",
          TempGenericChartSetup."X-Axis Title", 1, false); // 1 is For Dimension

        Assert.AreEqual(DimensionNameToSet, TempGenericChartSetup."X-Axis Field Name", 'XDimension Name Matches');
        Assert.AreEqual(DimensionNameToSet, TempGenericChartSetup."X-Axis Title", 'XDimension Title Matches');

        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Insert();

        // Add Measures
        MeasureIndex := 1;
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName, MeasureID,
          MeasureIndex - 1, DataMeasureType,
          DataAggregationType);

        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        // Save
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Chart.Modify();

        // [WHEN] Retrieve the properties from the query chart XML
        CreateBuilderFromChart(Chart, ChartBuilder);

        // [THEN] Chart Properties
        VerifyChartSourceProperties(ChartBuilder, SourceType, SourceName, SourceID, DefaultChartDescription);
        Clear(Chart);
        Chart.SetRange(ID, ChartCode);
        Chart.FindFirst();
        GenericChartMgt.RetrieveXML(
          Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartCaptionsBuf, TempGenericChartMemoBuf, TempGenericChartFilter);
        RetrievedDescription := TempGenericChartMemoBuf.GetMemo(GenericChartMgt.DescriptionCode(), GenericChartMgt.GetUserLanguage());
        VerifyChartSourceProperties(
          ChartBuilder, TempGenericChartSetup."Source Type", SourceName, TempGenericChartSetup."Source ID", RetrievedDescription);

        // Verify Dimensions
        VerifyChartDimensions(ChartBuilder, HasXDimension, 1, XDimensionID, XDimensionName, ShowXDimensionTitle);
        VerifyChartDimensions(ChartBuilder, HasZDimension, 2, ZDimensionID, ZDimensionName, ShowZDimensionTitle);

        // Verify Measures
        Assert.AreEqual(CountOfMeasures, ChartBuilder.MeasureCount, 'Count of Measures Match');

        for MeasureIndex := 1 to 4 do
            VerifyChartMeasure(ChartBuilder,
              MeasureIndex = 1, MeasureIndex - 1,
              MeasureID,
              MeasureName,
              DataMeasureType,
              DataAggregationType);

        VerifyChartFilters(ChartBuilder, FilterIndex, FilterFieldName, FilterFieldValue, FilterFieldId, FilterCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyChart()
    var
        Chart: Record Chart;
        CopiedChart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        InStream: InStream;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        MeasureName: array[4] of Text[50];
        TargetChartCode: Code[20];
        SourceChartXml: Text;
        TargetChartXml: Text;
        ChartXmlLine: Text;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Insert();

        // Add Measures
        MeasureIndex := 1;
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName[MeasureIndex], MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        // Save
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Chart.Modify();

        // [WHEN] Copy the source chart to the Target Chart by invoking copychart method.
        TargetChartCode := GenerateRandomChartCode();
        GenericChartMgt.CopyChart(Chart, TargetChartCode, TargetChartCode);
        CopiedChart.SetRange(ID, TargetChartCode);
        CopiedChart.FindFirst();
        CopiedChart.CalcFields(BLOB);
        CopiedChart.BLOB.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.ReadText(ChartXmlLine);
            TargetChartXml := TargetChartXml + ChartXmlLine;
        end;
        Clear(InStream);
        Clear(ChartXmlLine);

        // [THEN] Retrieve the fields in target chart and verify the changes.
        Chart.CalcFields(BLOB);
        Chart.BLOB.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.ReadText(ChartXmlLine);
            SourceChartXml := SourceChartXml + ChartXmlLine;
        end;

        Assert.AreEqual(SourceChartXml, TargetChartXml, 'The copied chart xml matches source chart xml');
        Assert.AreEqual(TargetChartCode, CopiedChart.Name, 'Title of target chart matches what was entered');
    end;

    [Test]
    [HandlerFunctions('HandleLookupPage,HandleTableFieldsChooser')]
    [Scope('OnPrem')]
    procedure TestLookupObjectId()
    var
        Chart: Record Chart;
        "Field": Record "Field";
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterFieldName: Text[30];
        FilterFieldID: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Set the field info
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // [WHEN] Add the fields to chart object by invoking the two methods LookupObjectID and RetrieveFieldColumn
        CreateDefaultChart(Chart, ChartCode);

        TempGenericChartSetup.Validate(ID, Chart.ID);
        TempGenericChartSetup.Validate("Source Type", SourceType);

        SourceIDToSet := SourceID;
        SourceTypeToSet := TempGenericChartSetup."Source Type"::Table;
        GenericChartMgt.LookUpObjectId(
          TempGenericChartSetup."Source Type"::Table, TempGenericChartSetup."Source ID", TempGenericChartSetup."Object Name");

        FilterFieldID := 20;
        FilterFieldName := GetFieldNameFromID(TempGenericChartSetup."Source ID", FilterFieldID);
        DimensionNameToSet := FilterFieldName;

        GenericChartMgt.RetrieveFieldColumn(
          TempGenericChartSetup,
          TempGenericChartFilter."Filter Field ID",
          TempGenericChartFilter."Filter Field Name",
          TempGenericChartFilter."Filter Field Name", 0, false);
        GetFieldsForTable(Field, SourceIDToSet, 0);

        // [THEN] The Lookup and Filter set values are set properly
        Assert.AreEqual(SourceID, TempGenericChartSetup."Source ID", 'Expected Source ID Matches');
        Assert.AreEqual(SourceName, TempGenericChartSetup."Object Name", 'Expected Source ID Matches');
        Assert.AreEqual(ActualFieldsListCount, Field.Count, 'count of fields match');
        Assert.AreEqual(FilterFieldID, TempGenericChartFilter."Filter Field ID", 'Filter ID Matches');
        Assert.AreEqual(FilterFieldName, TempGenericChartFilter."Filter Field Name", 'Filter Name Matches');
        Assert.AreEqual(Field.GetFilter(Type), ActualTypeFilter, 'Filter String Matches Expected for Filter');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureNonNumericFieldErrorForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[50];
        ShowXDimensionTitle: Boolean;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);
        MeasureIndex := 1;
        MeasureID[MeasureIndex] := XDimensionID;

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [WHEN] Save Chart with Measure set to Non-numeric field
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          XDimensionName, MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        // [THEN] Error is displayed when Measure is saved with a non-numeric field
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        CompareFilterStrings(
          StrSubstNo(DimensionMeasureInvalidError, TempGenericChartSetup."Source ID", TypeFilterText(2), XDimensionName, GetFieldClassFilter()),
          GetLastErrorText,
          'Error is returned when saving an Measure field which is non-numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureNonNumericFieldErrorForQuery()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: DotNet DataMeasureType;
        DataAggregationType: DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[50];
        ShowXDimensionTitle: Boolean;
        MeasureIndex: Integer;
        MeasureID: Integer;
        MeasureName: Text[50];
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a query based chart
        Initialize();
        GetDefaultSourceQueryInfo(SourceName, SourceID, SourceType);

        // Y Axis
        MeasureIndex := 0;
        DataMeasureType := DataMeasureType.StackedColumn100;
        GetDefaultMeasureInfoForQuery(DataAggregationType, MeasureID, MeasureName);

        // X Axis
        GetDefaultXDimensionInfoForQuery(XDimensionID, XDimensionName, ShowXDimensionTitle);

        // FILTERS
        GetDefaultFilterInfoForQuery(FilterFieldName, FilterFieldValue, FilterFieldId);

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        // SetChartDimensions(TempGenericChartSetup,1,XDimensionID,XDimensionName,XDimensionName,ShowXDimensionTitle);
        // TempGenericChartSetup.Insert();

        // Add Measures
        MeasureIndex := 1;
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          XDimensionName, XDimensionID,
          MeasureIndex - 1, DataMeasureType,
          DataAggregationType);

        // AddFiltersToChart(TempGenericChartSetup,TempGenericChartFilter,FilterFieldId,FilterFieldName,FilterIndex,FilterFieldValue);
        // Save
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.VerifyFailure(NothingInsideTheFilter, 'Error is returned when saving an Measure field which is non-numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimensionsDuplicateFieldsErrorForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        ShowXDimensionTitle := true;
        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        // [WHEN] Set Chart to have duplicate X dimensions
        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        SetChartDimensions(TempGenericChartSetup, 2, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Insert();

        // [THEN] Duplicate dimensions can be saved only checks are implemented in the page.
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Chart.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDuplicateMeasuresForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionName: Text[50];
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        MeasureName: array[4] of Text[50];
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [WHEN] Save Chart with Duplicate Measures
        MeasureIndex := 1;
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          XDimensionName, MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        MeasureIndex := 2;
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName[MeasureIndex], MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName[MeasureIndex], MeasureID[MeasureIndex],
          MeasureIndex, DataMeasureType[MeasureIndex + 1],
          DataAggregationType[MeasureIndex]);

        // [THEN] Error is not displayed and save is allowed, since validation is done in the page
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidSourceIDError()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();

        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        CreateDefaultChart(Chart, ChartCode);

        // [WHEN] Create a Chart wit an invalid source id
        SourceID := -LibraryRandom.RandInt(100);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [THEN] Error is displayed and save is not allowed.
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.ExpectedError(StrSubstNo(SourceIDValidationError, TempGenericChartSetup."Source Type", SourceID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimensionsNonExistentFieldNameforTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        ShowXDimensionTitle := true;
        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        // [WHEN] Save Chart with X dimensions set to negative field id
        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("X-Axis Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartSetup.Validate("X-Axis Field Name", Chart.ID);
        TempGenericChartSetup.Insert();

        // [THEN] Error is displayed when dimension X is saved
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        CompareFilterStrings(
          StrSubstNo(DimensionMeasureInvalidErrorType0, TempGenericChartSetup."Source ID", Chart.ID, GetFieldClassFilter()),
          GetLastErrorText,
          'Error is returned when saving an X dimension field which is numeric');

        // [WHEN] Save Chart with Z dimensions set to negative field id
        TempGenericChartSetup.DeleteAll();
        SetChartDimensions(TempGenericChartSetup, 2, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("Z-Axis Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartSetup.Validate("Z-Axis Field Name", Chart.ID);
        TempGenericChartSetup.Insert();

        // [THEN] Error is displayed when dimension Z is saved
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        CompareFilterStrings(
          StrSubstNo(DimensionMeasureInvalidErrorType0, TempGenericChartSetup."Source ID", Chart.ID, GetFieldClassFilter()),
          GetLastErrorText,
          'Error is returned when saving an Z dimension field which is numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimensionsNegativeFieldIdForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        ShowXDimensionTitle := true;
        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        // [WHEN] Save Chart with X dimensions set to negative field ID
        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("X-Axis Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartSetup.Insert();

        // [THEN] Error is not displayed and chart can be successfully saved
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          XDimensionID, TempGenericChartSetup."X-Axis Field ID", 'X Axis Field ID Passed in Is overridden with the ID from Field Name');

        // [WHEN] Save Chart with Z dimensions set to negative field ID
        TempGenericChartSetup.DeleteAll();
        SetChartDimensions(TempGenericChartSetup, 2, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("Z-Axis Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartSetup.Insert();

        // [THEN] Error is not displayed and chart can be successfully saved
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          XDimensionID, TempGenericChartSetup."Z-Axis Field ID", 'Z Axis Field ID Passed in Is overridden with the ID from Field Name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureNonExistentFieldNameForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        MeasureName: Text[50];
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);
        MeasureIndex := 1;

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [WHEN] Save Chart with Measure set to Non-Existent field name
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName, MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        TempGenericChartYAxis.Validate("Y-Axis Measure Field Name", Chart.ID);
        TempGenericChartYAxis.Modify();

        // [THEN] Error is displayed when Measure is saved with a non existent field name
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        CompareFilterStrings(
          StrSubstNo(DimensionMeasureInvalidError, TempGenericChartSetup."Source ID", TypeFilterText(2), Chart.ID, GetFieldClassFilter()),
          GetLastErrorText,
          'Error is returned when saving an Measure field which is non-numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureNegativeFieldIdForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        MeasureName: Text[50];
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);
        MeasureIndex := 1;

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [WHEN] Save Chart with Measure set to Negative field ID
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName, MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        TempGenericChartYAxis.Validate("Y-Axis Measure Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartYAxis.Modify();

        // [THEN] Measure can be saved with a negative field id
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          MeasureID[MeasureIndex], TempGenericChartYAxis."Y-Axis Measure Field ID",
          'Measure Field ID Passed in Is overridden with the ID from Field Name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidFilterFieldNameForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);
        CreateDefaultChart(Chart, ChartCode);

        // Filters
        FilterIndex := 0;
        GetDefaultFilterInfoForTable(FilterFieldName, FilterFieldValue, FilterFieldId);

        // [WHEN] Create a Chart with an filter containing and invalid field name
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Filter
        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        TempGenericChartFilter.Validate("Filter Field Name", Chart.ID);
        TempGenericChartFilter.Modify();

        // [THEN] Error is displayed and save is not allowed.
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.ExpectedError(StrSubstNo(InvalidFilterFieldError, TempGenericChartSetup."Source ID", Chart.ID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeFilterFieldIDForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);
        CreateDefaultChart(Chart, ChartCode);

        // Filters
        FilterIndex := 0;
        GetDefaultFilterInfoForTable(FilterFieldName, FilterFieldValue, FilterFieldId);

        // [WHEN] Create a Chart wit an invalid source id
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Filter
        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        TempGenericChartFilter.Validate("Filter Field ID", -LibraryRandom.RandInt(100));
        TempGenericChartFilter.Modify();

        // [THEN] Error is not displayed and save is allowed, since validation is done in the page.
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          FilterFieldId, TempGenericChartFilter."Filter Field ID",
          'Filter Field ID Passed in Is overridden with the ID from Field Name (if the id is invalid)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidFilterFieldvalueForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);
        CreateDefaultChart(Chart, ChartCode);

        // Filters
        FilterIndex := 0;
        GetDefaultFilterInfoForTable(FilterFieldName, FilterFieldValue, FilterFieldId);

        // [WHEN] Create a Chart with an filter containing and invalid field value
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Filter
        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        TempGenericChartFilter.Validate("Filter Value", Chart.ID);
        TempGenericChartFilter.Modify();

        // [THEN] Save is allowed.
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidFilterFieldNameForQuery()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceQueryInfo(SourceName, SourceID, SourceType);
        CreateDefaultChart(Chart, ChartCode);

        // Filters
        FilterIndex := 0;
        GetDefaultFilterInfoForQuery(FilterFieldName, FilterFieldValue, FilterFieldId);

        // [WHEN] Create a Chart with an filter containing and invalid field name
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Filter
        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        TempGenericChartFilter.Validate("Filter Field Name", Chart.ID);
        TempGenericChartFilter.Modify();

        // [THEN] Error is displayed and save is not allowed.
        asserterror SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.VerifyFailure(NothingInsideTheFilter, 'Error is returned when saving an Measure field which is non-numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTableChartCountMeasureBlankFieldName()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary;
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        ChartBuilder: DotNet BusinessChartBuilder;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        CountOfMeasures: Integer;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        MeasureName: array[4] of Text[50];
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a table based chart with X Dimension and 4 measures
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        CountOfMeasures := 4;
        // Y Axis, Index is zero based in chart builder
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Measures
        for MeasureIndex := 1 to 4 do begin
            AddMeasureToChart(
              TempGenericChartSetup, TempGenericChartYAxis,
              MeasureName[MeasureIndex], MeasureID[MeasureIndex],
              MeasureIndex - 1, DataMeasureType[MeasureIndex],
              DataAggregationType[MeasureIndex]);
            if MeasureIndex = 1 then begin
                DataAggregationType[MeasureIndex] := DataAggregationType[MeasureIndex].Count;
                MeasureName[MeasureIndex] := '';
                MeasureID[MeasureIndex] := 0;
                TempGenericChartYAxis."Y-Axis Measure Field ID" := MeasureID[MeasureIndex];
                TempGenericChartYAxis."Y-Axis Measure Field Name" := MeasureName[MeasureIndex];
                TempGenericChartYAxis.Aggregation := ConvertAggregationToOption(DataAggregationType[MeasureIndex]);
                TempGenericChartYAxis.Modify();
            end;
        end;

        // [WHEN] Save the Chart and retrieve fields using chart builder.
        // Save
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Chart.Modify();

        TempGenericChartSetup.DeleteAll();
        TempGenericChartYAxis.DeleteAll();
        TempGenericChartFilter.DeleteAll();

        // Retrieve fields.
        CreateBuilderFromChart(Chart, ChartBuilder);
        FindChartByID(Chart, ChartCode);

        // [THEN] Retrieve fields using chart builder and verify.
        GenericChartMgt.RetrieveXML(
          Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartCaptionsBuf, TempGenericChartMemoBuf, TempGenericChartFilter);
        // Verify Measure
        Assert.AreEqual(CountOfMeasures, ChartBuilder.MeasureCount, 'Count of Measures Match');
        for MeasureIndex := 1 to 4 do begin
            VerifyChartMeasure(ChartBuilder,
              true, MeasureIndex - 1,
              MeasureID[MeasureIndex],
              MeasureName[MeasureIndex],
              DataMeasureType[MeasureIndex],
              DataAggregationType[MeasureIndex]);
            VerifyChartMeasureAgainstTable(ChartBuilder, TempGenericChartYAxis, true, MeasureIndex - 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimensionsIdAndNameMismatchForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
        MeasureID: array[4] of Integer;
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
        ZDimensionID: Integer;
        ZDimensionName: Text[80];
        ShowZDimensionTitle: Boolean;
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);

        // X Axis
        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        // Z Axis
        GetDefaultZDimensionsInfoForTable(ZDimensionID, ZDimensionName, ShowZDimensionTitle);

        ShowXDimensionTitle := true;
        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);

        // [WHEN] Save Chart with X dimensions set to negative field ID
        SetChartDimensions(TempGenericChartSetup, 1, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("X-Axis Field Name", ZDimensionName);
        TempGenericChartSetup.Insert();

        // [THEN] Error is not displayed and chart can be successfully saved
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          XDimensionName, TempGenericChartSetup."X-Axis Field Name",
          'X Axis Field Name Passed in Is overridden with the Name from Field ID');

        // [WHEN] Save Chart with Z dimensions set to negative field ID
        TempGenericChartSetup.DeleteAll();
        SetChartDimensions(TempGenericChartSetup, 2, XDimensionID, XDimensionName, XDimensionName, ShowXDimensionTitle);
        TempGenericChartSetup.Validate("Z-Axis Field Name", ZDimensionName);
        TempGenericChartSetup.Insert();

        // [THEN] Error is not displayed and chart can be successfully saved
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          XDimensionName, TempGenericChartSetup."Z-Axis Field Name",
          'Z Axis Field Name Passed in Is overridden with the Name from Field ID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureFieldIdAndNameMismatchForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        DataMeasureType: array[4] of DotNet DataMeasureType;
        DataAggregationType: array[4] of DotNet DataAggregationType;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        MeasureIndex: Integer;
        MeasureID: array[4] of Integer;
        MeasureName: Text[50];
        HasMeasure: array[4] of Boolean;
        ChartCode: Code[20];
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);

        // Y Axis, Index is Zero based
        MeasureIndex := 0;
        GetTableMeasures(HasMeasure, MeasureID, DataMeasureType, DataAggregationType);
        MeasureIndex := 1;

        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // [WHEN] Save Chart with Measure set to Negative field ID
        AddMeasureToChart(
          TempGenericChartSetup, TempGenericChartYAxis,
          MeasureName, MeasureID[MeasureIndex],
          MeasureIndex - 1, DataMeasureType[MeasureIndex],
          DataAggregationType[MeasureIndex]);

        TempGenericChartYAxis.Validate(
          "Y-Axis Measure Field Name", GetFieldNameFromID(TempGenericChartSetup."Source ID", MeasureID[MeasureIndex + 1]));
        TempGenericChartYAxis.Modify();

        // [THEN] Measure can be saved with a negative field id
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          MeasureName, TempGenericChartYAxis."Y-Axis Measure Field Name",
          'Measure Field Name Passed in Is overridden with the Name from Field ID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterFieldIDAndNameMismatchForTable()
    var
        Chart: Record Chart;
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        SourceName: Text[30];
        SourceID: Integer;
        SourceType: Option;
        FilterIndex: Integer;
        FilterFieldName: Text[30];
        FilterFieldValue: Text[250];
        FilterFieldId: Integer;
        ChartCode: Code[20];
        XDimensionID: Integer;
        XDimensionName: Text[80];
        ShowXDimensionTitle: Boolean;
    begin
        // [GIVEN] Create a Source Chart
        Initialize();
        GetDefaultSourceTableInfo(SourceName, SourceID, SourceType);
        CreateDefaultChart(Chart, ChartCode);

        // Filters
        FilterIndex := 0;
        GetDefaultFilterInfoForTable(FilterFieldName, FilterFieldValue, FilterFieldId);

        GetDefaultXDimensionsInfoForTable(XDimensionID, XDimensionName, ShowXDimensionTitle);

        // [WHEN] Create a Chart wit an invalid source id
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType, SourceID, SourceName);
        TempGenericChartSetup.Insert();

        // Add Filter
        AddFiltersToChart(TempGenericChartSetup, TempGenericChartFilter, FilterFieldId, FilterFieldName, FilterIndex, FilterFieldValue);
        TempGenericChartFilter.Validate("Filter Field Name", CopyStr(XDimensionName, 1, 30));
        TempGenericChartFilter.Modify();

        // [THEN] Error is not displayed and save is allowed, since validation is done in the page.
        SaveChartWithDefaultDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Chart.Modify();
        RetrieveChartWithoutDescription(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        Assert.AreEqual(
          FilterFieldName, TempGenericChartFilter."Filter Field Name",
          'Filter Field ID Passed in Is overridden with the ID from Field Name (if the id is invalid)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrieveFieldColumnIdFromNameTable()
    var
        "Field": Record "Field";
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        ObjType: Option " ","Table","Query";
        ObjID: Integer;
        FoundID: Integer;
        Step: Integer;
    begin
        Field.SetRange(TableNo, DATABASE::"Sales Header");
        Field.FindSet();
        Step := LibraryRandom.RandInt(Field.Count);
        if Step = Field.Count then
            Step := Field.Count - 1;
        Field.Next(Step);
        ObjType := ObjType::Table;
        ObjID := DATABASE::"Sales Header";
        GenericChartMgt.RetrieveFieldColumnIDFromName(ObjType, ObjID, FoundID, Field.FieldName);
        Assert.AreEqual(Field."No.", FoundID, 'Retrieving name of field in a table based on table no and field no');
    end;

    [Scope('OnPrem')]
    procedure TestRetrieveFieldColumnIdFromNameQuery()
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        ObjType: Option " ","Table","Query";
        ObjID: Integer;
        FoundID: Integer;
    begin
        ObjType := ObjType::Query;
        ObjID := QUERY::"Trailing Sales Order Qry";
        GenericChartMgt.RetrieveFieldColumnIDFromName(ObjType, ObjID, FoundID, 'ShipmentDate');
        Assert.AreEqual(2, FoundID, 'Retrieving name of column in a query based on table no and field no');
        GenericChartMgt.RetrieveFieldColumnIDFromName(ObjType, ObjID, FoundID, 'Status');
        Assert.AreEqual(3, FoundID, 'Retrieving name of column in a query based on table no and field no');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuildFilterText()
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        FText: Text[250];
        Inp: Text[100];
        ExpectedText: Text[250];
    begin
        MakeRandomTextString(LibraryRandom.RandInt(100), FText);
        MakeRandomTextString(LibraryRandom.RandInt(100), Inp);
        ExpectedText := CopyStr(FText + ' ; ' + Inp, 1, MaxStrLen(ExpectedText));
        GenericChartMgt.BuildFilterText(FText, Inp);
        Assert.AreEqual(ExpectedText, FText, 'Building filter text without exceeding maximum length');
        MakeRandomTextString(240, FText);
        MakeRandomTextString(20, Inp);
        ExpectedText := CopyStr(FText + ',...', 1, MaxStrLen(ExpectedText));
        GenericChartMgt.BuildFilterText(FText, Inp);
        Assert.AreEqual(ExpectedText, FText, 'Building filter text length 240 with exceeding of maximum length');
        MakeRandomTextString(248, FText);
        MakeRandomTextString(20, Inp);
        ExpectedText := CopyStr(FText + '..', 1, MaxStrLen(ExpectedText));
        GenericChartMgt.BuildFilterText(FText, Inp);
        Assert.AreEqual(ExpectedText, FText, 'Building filter text length 248 with exceeding of maximum length');
    end;

    [Scope('OnPrem')]
    procedure TestGetQueryCountColumnName()
    var
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        Chart: Record Chart;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        ChartCode: Code[20];
        SourceType: Option " ","Table","Query";
        CountColumnName: Text[50];
    begin
        CreateDefaultChart(Chart, ChartCode);
        CreateGeneratorFromChart(Chart, TempGenericChartSetup, SourceType::Query, QUERY::"Acc. Sched. Line Desc. Count", TableSalesheader);
        TempGenericChartSetup.Insert();
        CountColumnName := GenericChartMgt.GetQueryCountColumnName(TempGenericChartSetup);
        Assert.AreEqual('Count_', CountColumnName, 'Retrieval of name of column with aggregation = Count');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetAggregationType()
    var
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
    begin
        Clear(TempGenericChartQueryColumn);
        TempGenericChartQueryColumn.Insert();
        TempGenericChartQueryColumn.SetAggregationType('none');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::None, 'Setting aggregation type for query column to None');
        TempGenericChartQueryColumn.SetAggregationType('count');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::Count, 'Setting aggregation type for query column to Count');
        TempGenericChartQueryColumn.SetAggregationType('sum');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::Sum, 'Setting aggregation type for query column to Sum');
        TempGenericChartQueryColumn.SetAggregationType('min');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::Min, 'Setting aggregation type for query column to Min');
        TempGenericChartQueryColumn.SetAggregationType('max');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::Max, 'Setting aggregation type for query column to Max');
        TempGenericChartQueryColumn.SetAggregationType('average');
        Assert.IsTrue(TempGenericChartQueryColumn."Aggregation Type" = TempGenericChartQueryColumn."Aggregation Type"::Avg, 'Setting aggregation type for query column to Average');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetTitle()
    var
        GenericChartSetup: Record "Generic Chart Setup";
    begin
        GenericChartSetup.Init();
        GenericChartSetup.Validate(Name, 'TestName');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestYAxisMeasureFieldID()
    var
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
    begin
        //TAB9182
        TempGenericChartYAxis.Init();
        TempGenericChartYAxis."Y-Axis Measure Field ID" := 1;
        TempGenericChartYAxis.Insert(true);
        TempGenericChartYAxis.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAggregations()
    var
        GenericChartQueryColumn: Record "Generic Chart Query Column";
    begin
        //TAB9183
        GenericChartQueryColumn.SetAggregationType(Text000);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::None);
        GenericChartQueryColumn.SetAggregationType(Text001);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::Count);
        GenericChartQueryColumn.SetAggregationType(Text002);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::Sum);
        GenericChartQueryColumn.SetAggregationType(Text003);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::Min);
        GenericChartQueryColumn.SetAggregationType(Text004);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::Max);
        GenericChartQueryColumn.SetAggregationType(Text005);
        GenericChartQueryColumn.TestField("Aggregation Type", GenericChartQueryColumn."Aggregation Type"::Avg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldTypeMapping()
    var
        GenericChartQueryColumn: Record "Generic Chart Query Column";
        "Field": Record "Field";
    begin
        SetAndVerifyColumnDataType(Field.Type::Date, GenericChartQueryColumn."Column Data Type"::Date);
        SetAndVerifyColumnDataType(Field.Type::Time, GenericChartQueryColumn."Column Data Type"::Time);
        SetAndVerifyColumnDataType(Field.Type::DateFormula, GenericChartQueryColumn."Column Data Type"::DateFormula);
        SetAndVerifyColumnDataType(Field.Type::Decimal, GenericChartQueryColumn."Column Data Type"::Decimal);
        SetAndVerifyColumnDataType(Field.Type::Text, GenericChartQueryColumn."Column Data Type"::Text);
        SetAndVerifyColumnDataType(Field.Type::Code, GenericChartQueryColumn."Column Data Type"::Code);
        SetAndVerifyColumnDataType(Field.Type::Binary, GenericChartQueryColumn."Column Data Type"::Binary);
        SetAndVerifyColumnDataType(Field.Type::Boolean, GenericChartQueryColumn."Column Data Type"::Boolean);
        SetAndVerifyColumnDataType(Field.Type::Integer, GenericChartQueryColumn."Column Data Type"::Integer);
        SetAndVerifyColumnDataType(Field.Type::Option, GenericChartQueryColumn."Column Data Type"::Option);
        SetAndVerifyColumnDataType(Field.Type::BigInteger, GenericChartQueryColumn."Column Data Type"::BigInteger);
        SetAndVerifyColumnDataType(Field.Type::DateTime, GenericChartQueryColumn."Column Data Type"::DateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilters()
    var
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        GenericChartFilters: Page "Generic Chart Filters";
        i: Integer;
        j: Integer;
    begin
        j := LibraryRandom.RandInt(20);
        for i := 1 to j do begin
            TempGenericChartFilter.ID := '';
            TempGenericChartFilter."Line No." := 10000 * i;
            TempGenericChartFilter."Filter Field ID" := i;
            TempGenericChartFilter."Filter Field Name" := Format(i);
            TempGenericChartFilter."Filter Value" := Format(i);
            TempGenericChartFilter.Insert();
        end;
        GenericChartFilters.SetFilters(TempGenericChartFilter);
        TempGenericChartFilter.DeleteAll();
        GenericChartFilters.GetFilters(TempGenericChartFilter);
        Assert.AreEqual(j, TempGenericChartFilter.Count, 'Number of TempGenericChart filter records retrieved.');
        TempGenericChartFilter.FindSet();
        i := 0;
        repeat
            i += 1;
            TempGenericChartFilter.TestField(ID, '');
            TempGenericChartFilter.TestField("Line No.", 10000 * i);
            TempGenericChartFilter.TestField("Filter Field ID", i);
            TempGenericChartFilter.TestField("Filter Field Name", Format(i));
            TempGenericChartFilter.TestField("Filter Value", Format(i));
        until TempGenericChartFilter.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyFilter()
    var
        GenericCharts: TestPage "Generic Charts";
    begin
        // Test of Onopen trigger
        GenericCharts.OpenView();
        GenericCharts.Close();
    end;

    [Test]
    [HandlerFunctions('HandleMemoTooLongMessage')]
    [Scope('OnPrem')]
    procedure TestMemo()
    var
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        TooLongText: Text;
    begin
        TempGenericChartMemoBuf.Code := '';
        TempGenericChartMemoBuf."Language Code" := DANLanguageCodeTxt;
        TempGenericChartMemoBuf.SetMemoText(DANLanguageMemoTxt);
        TempGenericChartMemoBuf.Insert();
        TempGenericChartMemoBuf."Language Code" := ENULanguageCodeTxt;
        TempGenericChartMemoBuf.SetMemoText(ENULanguageMemoTxt);
        TempGenericChartMemoBuf.Insert();
        TempGenericChartMemoBuf."Language Code" := LTHLanguageCodeTxt;
        TempGenericChartMemoBuf.SetMemoText(LTHLanguageMemoTxt);
        TempGenericChartMemoBuf.Insert();
        TempGenericChartMemoBuf.Get('', ENULanguageCodeTxt);
        Assert.AreEqual(Format(ENULanguageMemoTxt), TempGenericChartMemoBuf.GetMemoText(), MemoTxt);

        TooLongText := PadStr(TooLongText, 2501, 'A');
        TempGenericChartMemoBuf.SetMemoText(TooLongText);
    end;

    [Test]
    [HandlerFunctions('CaptionEditorRunModalHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerBalanceByCityAndMeasureCaptionWithAssistEdit()
    var
        Chart: Record Chart;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        ChartSetup: TestPage "Generic Chart Setup";
        ChartBuilder: DotNet BusinessChartBuilder;
        MultilanguageText: DotNet BusinessChartMultiLanguageText;
        ChartName: Text[30];
        ChartID: Code[20];
        Index: Integer;
    begin
        ChartID := 'TST-CAP-1';
        ChartName := 'Test Measure Caption Name';
        ValidateEntryDoesNotExist(ChartID);
        OpenAndInitializeCustomerBalanceByCity(ChartSetup, ChartID, ChartName);
        Assert.AreEqual(
          Format(RequiredMeasureCaptionTxt), Format(ChartSetup.RequiredMeasureCaption.Value), TestNameRequiredMeasureCaptionTxt);
        ChartSetup.RequiredMeasureCaption.AssistEdit();
        CommitCustomerBalanceByCity(ChartSetup, ChartID, ChartName);
        Assert.AreEqual(Format(RequiredMeasureCaptionChangedTxt),
          Format(ChartSetup.RequiredMeasureCaption.Value), TestNameRequiredMeasureCaptionTxt);

        ChartSetup.RequiredMeasureCaption.SetValue(RequiredMeasureCaptionTxt);
        CommitCustomerBalanceByCity(ChartSetup, ChartID, ChartName);

        GetChartFromDB(Chart, ChartID);
        ValidateChartEntryExist(Chart, ChartID, ChartName);
        GetChartBuilder(Chart, ChartBuilder);
        ValidateStandardCustomerBalanceByCityValues(ChartBuilder);

        MultilanguageText := ChartBuilder.GetMultilanguageMeasureCaption(0);
        Assert.AreEqual(4, MultilanguageText.Count, TestNameRequiredMeasureLanguageCountTxt);
        Assert.AreEqual(Format(RequiredMeasureCaptionTxt),
          MultilanguageText.GetText(GenericChartMgt.GetUserLanguage()), TestNameRequiredMeasureCaptionTxt);
        for Index := 1 to GetMaxLanguageCount() do
            Assert.AreEqual(Format(RequiredMeasureCaptionChangedTxt + GetLanguage(Index)),
              MultilanguageText.GetText(GetLanguage(Index)), TestNameRequiredMeasureCaptionTxt + ' - ' + Format(Index));

        RemoveChartFromDB(ChartID);
    end;

    local procedure OpenAndInitializeCustomerBalanceByCity(var ChartSetup: TestPage "Generic Chart Setup"; ChartID: Text; ChartName: Text)
    var
        GenericChartSetup: Record "Generic Chart Setup";
        GenericChartYAxis: Record "Generic Chart Y-Axis";
        Cust: Record Customer;
    begin
        ChartSetup.OpenNew();
        ChartSetup.Name.Value := ChartName;
        ChartSetup.ID.Value := ChartID;
        ChartSetup."Source Type".SetValue(GenericChartSetup."Source Type"::Table);
        ChartSetup."Source ID".SetValue(DATABASE::Customer);
        ChartSetup.RequiredMeasureColumn.SetValue(Cust.FieldName(Balance));
        ChartSetup.RequiredMeasureAggregation.SetValue(GenericChartYAxis.Aggregation::Sum);
        ChartSetup.RequiredMeasureType.SetValue(GenericChartYAxis."Chart Type"::ColumnStacked);
        ChartSetup.RequiredMeasureCaption.SetValue(RequiredMeasureCaptionTxt);
        ChartSetup."X-Axis Field".SetValue(Cust.FieldName(City));
        ChartSetup."Show X-Axis Title".SetValue(true);
        ChartSetup."X-Axis Title".SetValue(XAxisTitleTxt);
        ChartSetup."Data Point X Label".SetValue(XAxisDatapointTxt);
        ChartSetup."Show Y-Axis Title".SetValue(true);
        ChartSetup."Y-Axis Title".SetValue(YAxisTitleTxt);
    end;

    local procedure CommitCustomerBalanceByCity(var ChartSetup: TestPage "Generic Chart Setup"; ChartID: Code[20]; ChartName: Text[30])
    begin
        // It is necessary to move next/previous to get the ChartDefinition commited to blob in the DB.
        ChartSetup.Next(); // This line does the actual commit to the DB.
        ChartSetup.GotoKey(ChartID); // Getting back to the original record.
        // Ensure that we are actually on the expected record.
        Assert.AreEqual(ChartName, ChartSetup.Name.Value, ChartSetupNotShowingExpectedRecordTxt);
        Assert.AreEqual(ChartID, ChartSetup.ID.Value, ChartSetupNotShowingExpectedRecordTxt);
    end;

    local procedure GetChartFromDB(var Chart: Record Chart; ChartID: Code[20])
    begin
        Chart.SetRange(ID, ChartID);
        if not Chart.FindFirst() then
            Assert.Fail(StrSubstNo(ChartNotFoundErr, ChartID))
    end;

    local procedure RemoveChartFromDB(ChartID: Code[20])
    var
        Chart: Record Chart;
    begin
        Chart.SetRange(ID, ChartID);
        if Chart.FindFirst() then
            Chart.Delete();
    end;

    local procedure GetChartBuilder(var Chart: Record Chart; var chartBuilder: DotNet BusinessChartBuilder): Boolean
    var
        InStream: InStream;
    begin
        if not Chart.BLOB.HasValue() then
            exit(false);
        Chart.CalcFields(BLOB);
        Chart.BLOB.CreateInStream(InStream);
        chartBuilder := chartBuilder.FromStream(InStream);
        exit(true)
    end;

    local procedure GetLanguage(Number: Integer) LanguageCode: Code[3]
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        if Number = 1 then begin
            LanguageCode := LanguageCode1Txt;
            if GenericChartMgt.GetUserLanguage() = LanguageCode then
                LanguageCode := LanguageCode1AlternativeTxt
        end;

        if Number = 2 then begin
            LanguageCode := LanguageCode2Txt;
            if GenericChartMgt.GetUserLanguage() = LanguageCode then
                LanguageCode := LanguageCode2AlternativeTxt
        end;

        if Number = 3 then begin
            LanguageCode := LanguageCode3Txt;
            if GenericChartMgt.GetUserLanguage() = LanguageCode then
                LanguageCode := LanguageCode3AlternativeTxt
        end;

        if Number > GetMaxLanguageCount() then
            Assert.Fail(StrSubstNo(LanguageNotDefinedErr, GetMaxLanguageCount()));
    end;

    local procedure GetMaxLanguageCount(): Integer
    begin
        exit(3);
    end;

    local procedure AddFiltersToChart(var TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary; FilterFieldID: Integer; FilterFieldName: Text[30]; FilterIndex: Integer; FilterValue: Text[250])
    begin
        TempGenericChartFilter.Validate(ID, TempGenericChartSetup.ID);
        TempGenericChartFilter.Validate("Line No.", (FilterIndex + 1) * 10000);
        if TempGenericChartSetup."Source Type" = TempGenericChartSetup."Source Type"::Table then begin
            TempGenericChartFilter.Validate("Filter Field ID", FilterFieldID);
            TempGenericChartFilter.Validate("Filter Field Name", GetFieldNameFromID(TempGenericChartSetup."Source ID", FilterFieldID));
        end else
            TempGenericChartFilter.Validate("Filter Field Name", FilterFieldName);

        TempGenericChartFilter.Validate("Filter Value", FilterValue);
        GetFieldColumnNoName(
          TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartFilter."Filter Field ID",
          TempGenericChartFilter."Filter Field Name");
        TempGenericChartFilter.Insert();
    end;

    local procedure AddMeasureToChart(var TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var MeasureName: Text[50]; MeasureFieldID: Integer; MeasureIndex: Integer; DataMeasureType: DotNet DataMeasureType; DataAggregationType: DotNet DataAggregationType)
    begin
        TempGenericChartYAxis.Validate(ID, TempGenericChartSetup.ID);
        TempGenericChartYAxis.Validate("Line No.", (MeasureIndex + 1) * 10000);
        TempGenericChartYAxis.Validate("Y-Axis Measure Field ID", MeasureFieldID);
        if TempGenericChartSetup."Source Type" = TempGenericChartSetup."Source Type"::Table then
            MeasureName := GetFieldNameFromID(TempGenericChartSetup."Source ID", MeasureFieldID);
        TempGenericChartYAxis.Validate("Y-Axis Measure Field Name", MeasureName);
        TempGenericChartYAxis.Validate(Aggregation, ConvertAggregationToOption(DataAggregationType));
        TempGenericChartYAxis.Validate("Chart Type", ConvertMeasureTypeToOption(DataMeasureType));
        TempGenericChartYAxis.Insert();
    end;

    local procedure ClearGlobals()
    begin
        Clear(SourceIDToSet);
        Clear(SourceTypeToSet);
        Clear(ActualFieldsListCount);
        Clear(DimensionNameToSet);
        Clear(ActualTypeFilter);
    end;

    local procedure ConvertAggregationToOption(DataAggregationType: DotNet DataAggregationType): Integer
    var
        GenericChartYAxis: Record "Generic Chart Y-Axis";
    begin
        case Format(DataAggregationType) of
            'None':
                exit(GenericChartYAxis.Aggregation::None);
            'Count':
                exit(GenericChartYAxis.Aggregation::Count);
            'Sum':
                exit(GenericChartYAxis.Aggregation::Sum);
            'Min':
                exit(GenericChartYAxis.Aggregation::Min);
            'Max':
                exit(GenericChartYAxis.Aggregation::Max);
            'Avg':
                exit(GenericChartYAxis.Aggregation::Avg);
        end;
    end;

    local procedure ConvertMeasureTypeToOption(DataMeasureType: DotNet DataMeasureType): Integer
    var
        i: Integer;
    begin
        i := DataMeasureType;
        case i of
            10: // Column
                exit(0);
            0:
                exit(1);
            3:
                exit(2);
            11:
                exit(3);
            12:
                exit(4);
            13:
                exit(5);
            15:
                exit(6);
            16:
                exit(7);
            5:
                exit(8);
            17:
                exit(9);
            18:
                exit(10);
            21:
                exit(11);
            25:
                exit(12);
            33:
                exit(13);
        end;
    end;

    local procedure GetDefaultSourceQueryInfo(var SourceName: Text[30]; var SourceID: Integer; var SourceType: Option)
    var
        GenericChartSetup: Record "Generic Chart Setup";
    begin
        SourceName := 'Trailing Sales Order Qry';
        SourceID := 760;
        SourceType := GenericChartSetup."Source Type"::Query;
    end;

    local procedure GetDefaultXDimensionInfoForQuery(var XDimensionID: Integer; var XDimensionName: Text[80]; var ShowXDimensionTitle: Boolean)
    begin
        XDimensionID := 6;
        XDimensionName := 'CurrencyCode';
        ShowXDimensionTitle := true;
    end;

    local procedure GetDefaultMeasureInfoForQuery(var DataAggregationType: DotNet DataAggregationType; var MeasureID: Integer; var MeasureName: Text[50])
    begin
        MeasureID := 30; // Amount
        MeasureName := 'Amount';
        DataAggregationType := DataAggregationType.Count;
    end;

    local procedure GetFieldNameFromID(SourceID: Integer; FieldNo: Integer): Text[30]
    var
        SourceFieldRef: FieldRef;
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(SourceID);
        SourceFieldRef := SourceRecordRef.Field(FieldNo);
        exit(SourceFieldRef.Name);
    end;

    local procedure GetTableMeasures(var HasMeasure: array[4] of Boolean; var MeasureID: array[4] of Integer; var DataMeasureType: array[4] of DotNet DataMeasureType; var DataAggregationType: array[4] of DotNet DataAggregationType)
    var
        MeasureIndex: Integer;
    begin
        MeasureIndex := 1;
        HasMeasure[MeasureIndex] := true;
        DataMeasureType[MeasureIndex] := DataMeasureType[MeasureIndex].Line;
        MeasureID[MeasureIndex] := 60; // Amount
        DataAggregationType[MeasureIndex] := DataAggregationType[MeasureIndex].Count;

        // Measure Index 1
        MeasureIndex := 2;
        HasMeasure[MeasureIndex] := true;
        DataMeasureType[MeasureIndex] := DataMeasureType[MeasureIndex].Area;
        MeasureID[MeasureIndex] := 61; // Amount Including VAT
        DataAggregationType[MeasureIndex] := DataAggregationType[MeasureIndex].Sum;

        // Measure Index 2
        MeasureIndex := 3;
        HasMeasure[MeasureIndex] := true;
        DataMeasureType[MeasureIndex] := DataMeasureType[MeasureIndex].Column;
        MeasureID[MeasureIndex] := 130; // Prepayment %
        DataAggregationType[MeasureIndex] := DataAggregationType[MeasureIndex].Max;

        // Measure Index 3
        MeasureIndex := 4;
        HasMeasure[MeasureIndex] := true;
        DataMeasureType[MeasureIndex] := DataMeasureType[MeasureIndex].Point;
        MeasureID[MeasureIndex] := 140; // Prepmt. Payment Discount %
        DataAggregationType[MeasureIndex] := DataAggregationType[MeasureIndex].None;
    end;

    local procedure GetDefaultFilterInfoForTable(var FilterFieldName: Text[30]; var FilterFieldValue: Text[250]; var FilterFieldId: Integer)
    begin
        FilterFieldName := 'Posting Date';
        FilterFieldValue := '<> TODAY';
        FilterFieldId := 20;
    end;

    local procedure GetDefaultFilterInfoForQuery(var FilterFieldName: Text[30]; var FilterFieldValue: Text[250]; var FilterFieldId: Integer)
    begin
        FilterFieldName := 'CurrencyCode';
        FilterFieldValue := '<> USD';
        FilterFieldId := 6;
    end;

    local procedure CreateDefaultChart(var Chart: Record Chart; var ChartCode: Code[20])
    begin
        Chart.Init();
        if ChartCode = '' then
            ChartCode := GenerateRandomChartCode();
        Chart.Validate(ID, ChartCode);
        Chart.Validate(Name, Chart.ID);
        Chart.Insert();
    end;

    local procedure CreateGeneratorFromChart(var Chart: Record Chart; var TempGenericChartSetup: Record "Generic Chart Setup" temporary; SourceType: Option; SourceID: Integer; SourceName: Text[30])
    begin
        TempGenericChartSetup.Validate(ID, Chart.ID);
        TempGenericChartSetup.Validate("Source Type", SourceType);
        TempGenericChartSetup.Validate("Source ID", SourceID);
        TempGenericChartSetup.Validate("Object Name", SourceName);
    end;

    local procedure CreateBuilderFromChart(var Chart: Record Chart; var ChartBuilder: DotNet BusinessChartBuilder)
    var
        InStream: InStream;
    begin
        Chart.CalcFields(BLOB);
        Chart.BLOB.CreateInStream(InStream);
        ChartBuilder := ChartBuilder.FromStream(InStream);
    end;

    local procedure GetDefaultSourceTableInfo(var SourceName: Text[30]; var SourceID: Integer; var SourceType: Option)
    var
        GenericChartSetup: Record "Generic Chart Setup";
    begin
        SourceName := 'Sales Header';
        SourceID := 36;
        SourceType := GenericChartSetup."Source Type"::Table;
    end;

    local procedure GetDefaultXDimensionsInfoForTable(var XDimensionID: Integer; var XDimensionName: Text[80]; var ShowXDimensionTitle: Boolean)
    begin
        XDimensionID := 3;
        XDimensionName := 'No.';
        ShowXDimensionTitle := true;
    end;

    local procedure GetDefaultZDimensionsInfoForTable(var ZDimensionID: Integer; var ZDimensionName: Text[80]; var ShowZDimensionTitle: Boolean)
    begin
        ZDimensionID := 6;
        ZDimensionName := 'Bill-to Name 2';
        ShowZDimensionTitle := false;
    end;

    local procedure GenerateRandomChartCode(): Text[20]
    var
        Chart: Record Chart;
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomCode(Chart.FieldNo(ID), DATABASE::Chart), 1, 20));
    end;

    local procedure GetFieldsForTable(var "Field": Record "Field"; SourceTableNo: Integer; FilterType: Integer)
    begin
        Field.SetRange(TableNo, SourceTableNo);
        case FilterType of
            0:
                Field.SetRange(Type);
            1, 2:
                Field.SetFilter(Type, TypeFilterText(FilterType));
        end;
        Field.SetFilter(Class, '<>%1', Field.Class::FlowFilter);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.FindSet();
    end;

    local procedure GetFieldColumnNoName(SourceType: Option " ","Table","Query"; SourceNo: Integer; var FieldColNo: Integer; var FieldColName: Text)
    var
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
        "Field": Record "Field";
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        Found: Boolean;
    begin
        case SourceType of
            SourceType::Table:
                if FieldColNo > 0 then begin
                    FieldColName := '';
                    if Field.Get(SourceNo, FieldColNo) then
                        FieldColName := Field.FieldName;
                end else begin
                    Field.SetRange(TableNo, SourceNo);
                    if Field.FindSet() then
                        repeat
                            if UpperCase(Field.FieldName) = UpperCase(FieldColName) then begin
                                Found := true;
                                FieldColNo := Field."No.";
                            end;
                        until (Field.Next() = 0) or Found;
                end;
            SourceType::Query:
                begin
                    GenericChartMgt.GetQueryColumnList(TempGenericChartQueryColumn, SourceNo, 0, false);
                    if FieldColNo > 0 then begin
                        FieldColName := '';
                        TempGenericChartQueryColumn.SetRange("Query Column No.", FieldColNo);
                        if TempGenericChartQueryColumn.FindFirst() then
                            FieldColName := TempGenericChartQueryColumn."Column Name";
                    end else
                        if TempGenericChartQueryColumn.FindSet() then
                            repeat
                                if UpperCase(TempGenericChartQueryColumn."Column Name") = UpperCase(FieldColName) then begin
                                    Found := true;
                                    FieldColNo := TempGenericChartQueryColumn."Query Column No.";
                                end;
                            until (TempGenericChartQueryColumn.Next() = 0) or Found;
                end;
        end;
    end;

    local procedure FindChartByID(var Chart: Record Chart; ChartCode: Code[20])
    begin
        Clear(Chart);
        Chart.SetRange(ID, ChartCode);
        Chart.FindFirst();
    end;

    local procedure SaveChartWithDefaultDescription(var Chart: Record Chart; var TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary)
    var
        TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary;
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        TempGenericChartMemoBuf.SetMemo(GenericChartMgt.DescriptionCode(), GenericChartMgt.GetUserLanguage(), DefaultChartDescription);
        GenericChartMgt.SaveChanges(Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter,
          TempGenericChartCaptionsBuf, TempGenericChartMemoBuf);
    end;

    local procedure RetrieveChartWithoutDescription(var Chart: Record Chart; var TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary)
    var
        TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary;
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        TempGenericChartSetup.DeleteAll();
        TempGenericChartYAxis.DeleteAll();
        TempGenericChartFilter.DeleteAll();
        GenericChartMgt.RetrieveXML(
          Chart, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartCaptionsBuf, TempGenericChartMemoBuf, TempGenericChartFilter);
    end;

    local procedure SetChartDimensions(var TempGenericChartSetup: Record "Generic Chart Setup" temporary; DimensionType: Integer; DimensionFieldId: Integer; DimensionFieldName: Text[80]; DimensionCaption: Text[80]; ShowDimensiontitle: Boolean)
    begin
        if TempGenericChartSetup."Source Type" = TempGenericChartSetup."Source Type"::Table then
            DimensionFieldName := GetFieldNameFromID(TempGenericChartSetup."Source ID", DimensionFieldId);
        if DimensionType = 1 then begin
            TempGenericChartSetup.Validate("X-Axis Field ID", DimensionFieldId);
            TempGenericChartSetup.Validate("X-Axis Field Name", DimensionFieldName);
            TempGenericChartSetup.Validate("X-Axis Title", DimensionCaption);
            TempGenericChartSetup.Validate("X-Axis Show Title", ShowDimensiontitle);
        end else
            if DimensionType = 2 then begin
                TempGenericChartSetup.Validate("Z-Axis Field ID", DimensionFieldId);
                TempGenericChartSetup.Validate("Z-Axis Field Name", DimensionFieldName);
                TempGenericChartSetup.Validate("Z-Axis Title", DimensionCaption);
                TempGenericChartSetup.Validate("Z-Axis Show Title", ShowDimensiontitle);
            end;
    end;

    local procedure SetAndVerifyColumnDataType(FieldType: Option; ExpectedColumnDataType: Option)
    var
        GenericChartQueryColumn: Record "Generic Chart Query Column";
    begin
        GenericChartQueryColumn.SetColumnDataType(FieldType);
        Assert.AreEqual(ExpectedColumnDataType, GenericChartQueryColumn."Column Data Type", ColumnDataTypeErr);
    end;

    local procedure VerifyChartSourceProperties(var ChartBuilder: DotNet BusinessChartBuilder; SourceType: Option; SourceName: Text[30]; SourceID: Integer; Description: Text)
    var
        GenericChartSetup: Record "Generic Chart Setup";
    begin
        if SourceType = GenericChartSetup."Source Type"::Table then begin
            Assert.AreEqual(SourceID, ChartBuilder.TableId, 'Table ID Matches');
            Assert.AreEqual(SourceName, ChartBuilder.TableName, 'Table Name Matches');
            Assert.AreEqual(true, ChartBuilder.HasTable, 'SourceType is Table');
            Assert.AreEqual(false, ChartBuilder.HasQuery, 'SourceType is not Query');
        end else begin
            Assert.AreEqual(SourceID, ChartBuilder.QueryId, 'Query ID Matches');
            Assert.AreEqual(SourceName, ChartBuilder.QueryName, 'Query Name Matches');
            Assert.AreEqual(false, ChartBuilder.HasTable, 'SourceType is not Table');
            Assert.AreEqual(true, ChartBuilder.HasQuery, 'SourceType is Query');
        end;

        Assert.AreEqual(Description, ChartBuilder.Description, 'Description Matches');
    end;

    local procedure VerifyChartDimensions(var ChartBuilder: DotNet BusinessChartBuilder; IsDimensionDefined: Boolean; DimensionType: Integer; DimensionFieldId: Integer; DimensionCaption: Text[250]; ShowDimensiontitle: Boolean)
    begin
        if DimensionType = 1 then
            if IsDimensionDefined then begin
                Assert.AreEqual(DimensionFieldId, ChartBuilder.XDimensionId, 'XDimension ID Matches');
                Assert.AreEqual(DimensionCaption, ChartBuilder.XDimensionName, 'XDimensionName Matches');
                Assert.AreEqual(true, ChartBuilder.HasXDimension, 'Has XDimension matches');
                Assert.AreEqual(ShowDimensiontitle, ChartBuilder.ShowXDimensionTitle, 'Show X Dimension Title matches');
            end;

        if DimensionType = 2 then
            if IsDimensionDefined then begin
                Assert.AreEqual(DimensionFieldId, ChartBuilder.ZDimensionId, 'ZDimension ID Matches');
                Assert.AreEqual(DimensionCaption, ChartBuilder.ZDimensionName, 'ZDimensionName Matches');
                Assert.AreEqual(true, ChartBuilder.HasZDimension, 'Has ZDimension matches');
                Assert.AreEqual(ShowDimensiontitle, ChartBuilder.ShowZDimensionTitle, 'Show Z Dimension Title matches');
            end;
    end;

    local procedure VerifyChartMeasure(var ChartBuilder: DotNet BusinessChartBuilder; IsMeasureDefinedAtIndex: Boolean; MeasureIndex: Integer; MeasureFieldID: Integer; MeasureName: Text[50]; DataMeasureType: DotNet DataMeasureType; DataAggregationType: DotNet DataAggregationType)
    begin
        Assert.AreEqual(
          IsMeasureDefinedAtIndex, ChartBuilder.HasMeasureField(MeasureIndex),
          StrSubstNo('Property: HasMeasure for measure field:%1 matches', MeasureIndex));
        if IsMeasureDefinedAtIndex then begin
            Assert.AreEqual(
              Format(DataMeasureType), Format(ChartBuilder.GetMeasureChartType(MeasureIndex)),
              StrSubstNo('Chart Type for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(MeasureFieldID, ChartBuilder.GetMeasureId(MeasureIndex), StrSubstNo('ID for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(
              Format(DataAggregationType), Format(ChartBuilder.GetMeasureOperator(MeasureIndex)),
              StrSubstNo('Aggregation Type for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(MeasureName, ChartBuilder.GetMeasureName(MeasureIndex), StrSubstNo('Name for Measure:%1 matches', MeasureIndex));
        end;
    end;

    local procedure VerifyChartMeasureAgainstTable(var ChartBuilder: DotNet BusinessChartBuilder; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; IsMeasureDefinedAtIndex: Boolean; MeasureIndex: Integer)
    begin
        Assert.AreEqual(
          IsMeasureDefinedAtIndex, ChartBuilder.HasMeasureField(MeasureIndex),
          StrSubstNo('Property: HasMeasure for measure field:%1 matches', MeasureIndex));
        TempGenericChartYAxis.SetRange("Line No.", (MeasureIndex + 1) * 10000);
        TempGenericChartYAxis.FindFirst();
        if IsMeasureDefinedAtIndex then begin
            Assert.AreEqual(
              Format(TempGenericChartYAxis."Chart Type"), Format(ChartBuilder.GetMeasureChartType(MeasureIndex)),
              StrSubstNo('Chart Type for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(
              TempGenericChartYAxis."Y-Axis Measure Field ID", ChartBuilder.GetMeasureId(MeasureIndex),
              StrSubstNo('ID for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(
              Format(TempGenericChartYAxis.Aggregation), Format(ChartBuilder.GetMeasureOperator(MeasureIndex)),
              StrSubstNo('Aggregation Type for Measure:%1 matches', MeasureIndex));
            Assert.AreEqual(
              TempGenericChartYAxis."Y-Axis Measure Field Name", ChartBuilder.GetMeasureName(MeasureIndex),
              StrSubstNo('Name for Measure:%1 matches', MeasureIndex));
        end;
    end;

    local procedure VerifyChartFilters(var ChartBuilder: DotNet BusinessChartBuilder; FilterIndex: Integer; FilterFieldName: Text[30]; FilterFieldValue: Text[250]; FilterFieldId: Integer; FilterCount: Integer)
    var
        ActualFilterFieldName: Text[30];
        ActualFilterFieldValue: Text[250];
        ActualFilterFieldId: Integer;
        ActualFilterCount: Integer;
    begin
        if ChartBuilder.HasQuery then begin
            ActualFilterFieldId := ChartBuilder.GetQueryFilterFieldId(FilterIndex);
            ActualFilterFieldName := ChartBuilder.GetQueryFilterFieldName(FilterIndex);
            ActualFilterFieldValue := ChartBuilder.GetQueryFilterValue(FilterIndex);
            ActualFilterCount := ChartBuilder.QueryFilterCount;
            Assert.AreEqual(0, ChartBuilder.TableFilterCount, 'Table filter count is zero when source type is set to query');
        end else begin
            ActualFilterFieldId := ChartBuilder.GetTableFilterFieldId(FilterIndex);
            ActualFilterFieldName := ChartBuilder.GetTableFilterFieldName(FilterIndex);
            ActualFilterFieldValue := ChartBuilder.GetTableFilterValue(FilterIndex);
            ActualFilterCount := ChartBuilder.TableFilterCount;
            Assert.AreEqual(0, ChartBuilder.QueryFilterCount, 'Query filter count is zero when source type is set to Table');
        end;

        if ActualFilterCount > 0 then begin
            Assert.AreEqual(FilterFieldId, ActualFilterFieldId, StrSubstNo('Filter field ID for Index:%1 matches', FilterIndex));
            Assert.AreEqual(FilterFieldName, ActualFilterFieldName, StrSubstNo('Filter field Name for Index:%1 matches', FilterIndex));
            Assert.AreEqual(FilterFieldValue, ActualFilterFieldValue, StrSubstNo('Filter field Value for Index:%1 matches', FilterIndex));
            Assert.AreEqual(FilterCount, ActualFilterCount, 'Filter count value matches');
        end else
            Assert.AreEqual(0, ActualFilterCount, 'Filters don''t exist ');
    end;

    local procedure TypeFilterText(Category: Integer): Text
    var
        DummyField: Record "Field";
    begin
        case Category of
            1:
                exit(
                  StrSubstNo(
                    '%1|%2|%3|%4|%5|%6|%7', DummyField.Type::Date, DummyField.Type::Time, DummyField.Type::DateFormula, DummyField.Type::Text, DummyField.Type::Code, DummyField.Type::Option, DummyField.Type::DateTime));
            2:
                exit(StrSubstNo('%1|%2|%3|%4|%5', DummyField.Type::Decimal, DummyField.Type::Binary, DummyField.Type::Integer, DummyField.Type::BigInteger, DummyField.Type::Duration));
        end;
    end;

    local procedure "Min"(A: Integer; B: Integer): Integer
    begin
        if A < B then
            exit(A);
        exit(B);
    end;

    local procedure GetFieldClassFilter(): Text
    begin
        exit('<>FlowFilter');
    end;

    local procedure CompareFilterStrings(ExpectedStr: Text; ActualStr: Text; ErrMsg: Text)
    var
        CompLength: Integer;
    begin
        ExpectedStr := CopyStr(ExpectedStr, 46);
        ActualStr := CopyStr(ActualStr, 46);
        CompLength := Min(StrLen(ExpectedStr), StrLen(ActualStr));
        Assert.AreEqual(CopyStr(ExpectedStr, 1, CompLength), CopyStr(ActualStr, 1, CompLength), CopyStr(ErrMsg, 1, 1024)); // Max length for Msg in AreEqual
    end;

    local procedure MakeRandomTextString(Length: Integer; var Output: Text[250])
    var
        AllowedChars: Text[36];
        i: Integer;
    begin
        AllowedChars := 'abcdefghijklmnopqrstuvwxyz0123456789';
        Output := '';
        for i := 1 to Length do
            Output := Output + CopyStr(AllowedChars, LibraryRandom.RandInt(MaxStrLen(AllowedChars)), 1);
    end;

    local procedure ValidateEntryDoesNotExist(ChartID: Code[20])
    var
        Chart: Record Chart;
    begin
        Chart.SetRange(ID, ChartID);
        if Chart.FindFirst() then
            Assert.Fail(ChartFoundInDBErr)
    end;

    local procedure ValidateChartEntryExist(var Chart: Record Chart; ChartID: Code[20]; ChartName: Text[30])
    begin
        Assert.AreEqual(Format(ChartName), Chart.Name, TextChartNameTestTxt);
        Assert.AreEqual(Format(ChartID), Chart.ID, TextChartNameTestTxt);
        if not Chart.BLOB.HasValue() then
            Assert.Fail(NoDataInBlobErr)
    end;

    local procedure ValidateStandardCustomerBalanceByCityValues(var ChartBuilder: DotNet BusinessChartBuilder)
    var
        Cust: Record Customer;
        AggregationType: DotNet DataAggregationType;
        MeasureType: DotNet DataMeasureType;
    begin
        Assert.IsTrue(ChartBuilder.HasTable, TestNameHasTableTxt);
        Assert.AreEqual(DATABASE::Customer, ChartBuilder.TableId, TestNameTableIDTxt);
        Assert.AreEqual(Cust.FieldName(Balance), ChartBuilder.GetMeasureName(0), TestNameRequiredMeasureColumnTxt);
        Assert.AreEqual(Format(AggregationType.Sum), Format(ChartBuilder.GetMeasureOperator(0)), TestNameRequiredMeasureAggregationTxt);
        Assert.AreEqual(Format(MeasureType.StackedColumn), Format(ChartBuilder.GetMeasureChartType(0)), TestNameRequiredMeasureTypeTxt);
        Assert.AreEqual(Format(RequiredMeasureCaptionTxt), Format(ChartBuilder.GetMeasureCaption(0)), TestNameRequiredMeasureCaptionTxt);
        Assert.AreEqual(Cust.FieldName(City), ChartBuilder.XDimensionName, TestNameXAxisTxt);
        Assert.AreEqual(Format(XAxisDatapointTxt), ChartBuilder.XDimensionCaption, TestNameXAxisDatapointTxt);
        Assert.IsTrue(ChartBuilder.ShowXDimensionTitle, TestNameShowXAxisTitleTxt);
        Assert.AreEqual(Format(XAxisTitleTxt), ChartBuilder.XDimensionTitle, TestNameXAxisTitleTxt);
        Assert.IsTrue(ChartBuilder.ShowYAxisTitle, TestNameShowYAxisTitleTxt);
        Assert.AreEqual(Format(YAxisTitleTxt), ChartBuilder.YAxisTitle, TestNameYAxisTitleTxt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleLookupPage(var ObjectsPage: TestPage Objects)
    var
        SourceID: Integer;
        SourceType: Option " ","Table","Query";
    begin
        SourceID := SourceIDToSet;
        Evaluate(SourceType, ObjectsPage.FILTER.GetFilter("Object Type"));
        Assert.AreEqual(SourceTypeToSet, SourceType, 'Verify that filter is set correctly');
        ObjectsPage.FILTER.SetFilter("Object ID", Format(SourceID));
        ObjectsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleTableFieldsChooser(var FieldsLookup: TestPage "Fields Lookup")
    begin
        Assert.AreEqual(Format(SourceIDToSet), FieldsLookup.FILTER.GetFilter(TableNo), 'Table No matches');
        ActualTypeFilter := FieldsLookup.FILTER.GetFilter(Type);
        ActualFieldsListCount := 0;
        repeat
            ActualFieldsListCount += 1;
        until not FieldsLookup.Next();
        FieldsLookup.First();
        FieldsLookup.FILTER.SetFilter(FieldName, DimensionNameToSet);
        Assert.AreEqual(DimensionNameToSet, Format(FieldsLookup.FieldName), 'Verify the correct Dimension Name has been selected');
        FieldsLookup.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleTooManyMeasuresMessage(MsgText: Text)
    begin
        Assert.AreEqual(StrSubstNo(MaxNoOfMeasures, 6), MsgText, 'Message when trying to customize with too many measures');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MemoEditorRunModalHandler(var Editor: TestPage "Generic Chart Memo Editor")
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        Editor.First();
        if not Editor.GotoKey(GenericChartMgt.DescriptionCode(), GenericChartMgt.GetUserLanguage()) then
            Editor.New();
        Editor."Language Code".SetValue(GenericChartMgt.GetUserLanguage());
        Editor.MemoText.SetValue(DescriptionTxt);

        Assert.AreEqual(GenericChartMgt.GetUserLanguage(), Editor."Language Code".Value, TestNameEditorLanguageFieldTxt);
        Assert.AreEqual(Format(DescriptionTxt), Editor.MemoText.Value, TestNameEditorTextFieldTxt);

        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(1));
        Editor.MemoText.SetValue(DescriptionTxt + GetLanguage(1));
        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(2));
        Editor.MemoText.SetValue(DescriptionTxt + GetLanguage(2));
        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(3));
        Editor.MemoText.SetValue(DescriptionTxt + GetLanguage(3));

        Assert.AreEqual(GetLanguage(3), Editor."Language Code".Value, TestNameEditorLanguageFieldTxt);
        Assert.AreEqual(Format(DescriptionTxt + GetLanguage(3)), Editor.MemoText.Value, TestNameEditorTextFieldTxt);

        Editor.New();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CaptionEditorRunModalHandler(var Editor: TestPage "Generic Chart Text Editor")
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        if not Editor.GotoKey(GenericChartMgt.RequiredMeasureCode(), GenericChartMgt.GetUserLanguage()) then
            Editor.New();

        Editor."Language Code".SetValue(GenericChartMgt.GetUserLanguage());
        Editor.Text.Value := RequiredMeasureCaptionChangedTxt;

        Assert.AreEqual(GenericChartMgt.GetUserLanguage(), Editor."Language Code".Value, TestNameEditorLanguageFieldTxt);
        Assert.AreEqual(Format(RequiredMeasureCaptionChangedTxt), Format(Editor.Text.Value), TestNameEditorTextFieldTxt);

        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(1));
        Editor.Text.SetValue(RequiredMeasureCaptionChangedTxt + GetLanguage(1));
        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(2));
        Editor.Text.SetValue(RequiredMeasureCaptionChangedTxt + GetLanguage(2));
        Editor.New();
        Editor."Language Code".SetValue(GetLanguage(3));
        Editor.Text.SetValue(RequiredMeasureCaptionChangedTxt + GetLanguage(3));

        Assert.AreEqual(GetLanguage(3), Editor."Language Code".Value, TestNameEditorLanguageFieldTxt);
        Assert.AreEqual(Format(RequiredMeasureCaptionChangedTxt + GetLanguage(3)), Format(Editor.Text.Value), TestNameEditorTextFieldTxt);

        Editor.New();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleMemoTooLongMessage(Message: Text[1024])
    begin
        Assert.AreEqual(StrSubstNo(TextMemoToBeTruncatedMsg, 2501, 2500), Message, MemoTestNameTxt)
    end;
}

