namespace System.Visualization;

using System;
using System.Apps;
using System.Environment;
using System.Globalization;
using System.Reflection;

codeunit 9180 "Generic Chart Mgt"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        MustSelectFieldErr: Label 'You must select the %1.';
#pragma warning restore AA0470
        NoFiltersSelectedTxt: Label '(No filters selected)';
#pragma warning disable AA0470
        TooManyMeasuresErr: Label 'You cannot select more than %1 measures when using the Customize Chart option.';
#pragma warning restore AA0470
        CountColumnNotFoundErr: Label 'You cannot select Count for this chart because the source query does not support this aggregation method.';
#pragma warning disable AA0470
        AggregationTypeForDecimalOnlyErr: Label 'The aggregation type %1 can only be selected for columns of type Decimal.';
#pragma warning restore AA0470
        DescriptionTok: Label 'DESCR.', Comment = 'DESCR.';
        XAxisTitleTok: Label 'X-TITLE', Comment = 'X-AXIS';
        YAxisTitleTok: Label 'Y-TITLE', Comment = 'Y-AXIS';
        ZAxisTitleTok: Label 'Z-TITLE', Comment = 'Y-AXIS';
        XAxisCaptionTok: Label 'X-CAPTION', Comment = 'X-AXIS';
        ZAxisCaptionTok: Label 'Z-CAPTION', Comment = 'Y-AXIS';
        RequiredTok: Label 'REQUIRED', Comment = 'REQUIRED';
        Optional1Tok: Label 'OPTIONAL1', Comment = 'OPTIONAL1';
        Optional2Tok: Label 'OPTIONAL2', Comment = 'OPTIONAL2';
        Optional3Tok: Label 'OPTIONAL3', Comment = 'OPTIONAL3';
        Optional4Tok: Label 'OPTIONAL4', Comment = 'OPTIONAL4';
        Optional5Tok: Label 'OPTIONAL5', Comment = 'OPTIONAL5';
        AggregationTxt: Label 'None,Count,Sum,Min,Max,Avg';

    [Scope('OnPrem')]
    procedure RetrieveXML(var Chart: Record Chart; var TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary)
    var
        chartBuilder: DotNet BusinessChartBuilder;
        i: Integer;
        FilterText: Text[250];
        CaptionCode: Code[10];
    begin
        TempGenericChartSetup.DeleteAll();
        Clear(TempGenericChartSetup);
        TempGenericChartCaptionsBuf.DeleteAll();
        Clear(TempGenericChartCaptionsBuf);
        TempGenericChartMemoBuf.DeleteAll();
        Clear(TempGenericChartMemoBuf);
        if not GetChartBuilder(Chart, chartBuilder) then
            exit;

        if chartBuilder.TableId > 0 then begin
            TempGenericChartSetup."Source Type" := TempGenericChartSetup."Source Type"::Table;
            TempGenericChartSetup."Source ID" := chartBuilder.TableId;
            TempGenericChartSetup."Object Name" := chartBuilder.TableName;
        end else begin
            TempGenericChartSetup."Source Type" := TempGenericChartSetup."Source Type"::Query;
            TempGenericChartSetup."Source ID" := chartBuilder.QueryId;
            TempGenericChartSetup."Object Name" := chartBuilder.QueryName;
        end;
        GetSourceIDName(TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."Object Name");

        BuildMemoBuf(TempGenericChartMemoBuf, DescriptionCode(), chartBuilder.GetMultilanguageDescription());

        // Filters:
        Clear(FilterText);
        BuildTempGenericChartFilter(TempGenericChartSetup, TempGenericChartFilter, chartBuilder, FilterText);
        TempGenericChartSetup."Filter Text" := FilterText;
        FinalizeFilterText(TempGenericChartSetup."Filter Text");
        // X, Y and Z axes:
        TempGenericChartSetup."X-Axis Field ID" := chartBuilder.XDimensionId;
        // Number of field
        TempGenericChartSetup."X-Axis Field Name" := chartBuilder.XDimensionName;
        // Name of field
        GetFieldColumnNoName(TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."X-Axis Field ID", TempGenericChartSetup."X-Axis Field Name", false);
        TempGenericChartSetup."X-Axis Show Title" := chartBuilder.ShowXDimensionTitle;
        BuildCaptionBuf(TempGenericChartCaptionsBuf, XAxisTitleCode(), chartBuilder.GetXDimensionMultilanguageTitle());
        BuildCaptionBuf(TempGenericChartCaptionsBuf, XAxisCaptionCode(), chartBuilder.GetXDimensionMultilanguageCaption());
        TempGenericChartSetup."Y-Axis Show Title" := chartBuilder.ShowYAxisTitle;
        BuildCaptionBuf(TempGenericChartCaptionsBuf, YAxisTitleCode(), chartBuilder.GetYAxisMultilanguageTitle());

        if chartBuilder.HasZDimension then begin
            TempGenericChartSetup."Z-Axis Field ID" := chartBuilder.ZDimensionId();
            TempGenericChartSetup."Z-Axis Field Name" := chartBuilder.ZDimensionName();
            GetFieldColumnNoName(TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."Z-Axis Field ID", TempGenericChartSetup."Z-Axis Field Name", false);
            TempGenericChartSetup."Z-Axis Show Title" := chartBuilder.ShowZDimensionTitle();
            BuildCaptionBuf(TempGenericChartCaptionsBuf, ZAxisTitleCode(), chartBuilder.GetZDimensionMultilanguageTitle());
            BuildCaptionBuf(TempGenericChartCaptionsBuf, ZAxisCaptionCode(), chartBuilder.GetZDimensionMultilanguageCaption());
        end;
        // Measures:
        TempGenericChartYAxis.DeleteAll();
        CaptionCode := RequiredMeasureCode();
        for i := 0 to chartBuilder.MeasureCount - 1 do begin
            TempGenericChartYAxis.Init();
            TempGenericChartYAxis.ID := Chart.ID;
            TempGenericChartYAxis."Line No." := 10000 * (i + 1);
            if chartBuilder.HasMeasureField(i) then begin
                TempGenericChartYAxis."Y-Axis Measure Field ID" := chartBuilder.GetMeasureId(i);
                TempGenericChartYAxis."Y-Axis Measure Field Name" := chartBuilder.GetMeasureName(i);
                BuildCaptionBuf(TempGenericChartCaptionsBuf, CaptionCode, chartBuilder.GetMultilanguageMeasureCaption(i));
                GetFieldColumnNoName(
                  TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartYAxis."Y-Axis Measure Field ID",
                  TempGenericChartYAxis."Y-Axis Measure Field Name", false);

                if CaptionCode = RequiredMeasureCode() then
                    CaptionCode := OptionalMeasure1Code()
                else
                    CaptionCode := IncStr(CaptionCode)
            end;
            TempGenericChartYAxis."Chart Type" := ChartType2GraphType(chartBuilder.GetMeasureChartType(i));
            TempGenericChartYAxis.Aggregation := Operator2Aggregation(chartBuilder.GetMeasureOperator(i));
            TempGenericChartYAxis.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure FillChartHelper(var chartBuilder: DotNet BusinessChartBuilder; TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary; var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary)
    var
        DataMeasureType: DotNet DataMeasureType;
        DataAggregationType: DotNet DataAggregationType;
        MultilanguageText: DotNet BusinessChartMultiLanguageText;
        CaptionCode: Code[10];
    begin
        ValidateChart(TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter);
        case TempGenericChartSetup."Source Type" of
            TempGenericChartSetup."Source Type"::Table:
                begin
                    chartBuilder.TableId(TempGenericChartSetup."Source ID");
                    chartBuilder.TableName(TempGenericChartSetup."Object Name");
                end;
            TempGenericChartSetup."Source Type"::Query:
                begin
                    chartBuilder.QueryId(TempGenericChartSetup."Source ID");
                    chartBuilder.QueryName(TempGenericChartSetup."Object Name");
                end;
        end;
        BuildMemoMultilanguageText(TempGenericChartMemoBuf, DescriptionCode(), MultilanguageText);
        chartBuilder.SetMultilanguageDescription(MultilanguageText);
        chartBuilder.XDimensionId := TempGenericChartSetup."X-Axis Field ID";
        chartBuilder.XDimensionName := TempGenericChartSetup."X-Axis Field Name";
        chartBuilder.ShowXDimensionTitle := TempGenericChartSetup."X-Axis Show Title";
        BuildMultilanguageText(TempGenericChartCaptionsBuf, XAxisTitleCode(), MultilanguageText);
        chartBuilder.SetXDimensionMultilanguageTitle(MultilanguageText);
        BuildMultilanguageText(TempGenericChartCaptionsBuf, XAxisCaptionCode(), MultilanguageText);
        chartBuilder.SetXDimensionMultilanguageCaption(MultilanguageText);
        chartBuilder.ZDimensionId := TempGenericChartSetup."Z-Axis Field ID";
        chartBuilder.ZDimensionName := TempGenericChartSetup."Z-Axis Field Name";
        chartBuilder.ShowZDimensionTitle := TempGenericChartSetup."Z-Axis Show Title";
        BuildMultilanguageText(TempGenericChartCaptionsBuf, ZAxisTitleCode(), MultilanguageText);
        chartBuilder.SetZDimensionMultilanguageTitle(MultilanguageText);
        BuildMultilanguageText(TempGenericChartCaptionsBuf, ZAxisCaptionCode(), MultilanguageText);
        chartBuilder.SetZDimensionMultilanguageCaption(MultilanguageText);

        // Y-Axis
        chartBuilder.ShowYAxisTitle := TempGenericChartSetup."Y-Axis Show Title";
        BuildMultilanguageText(TempGenericChartCaptionsBuf, YAxisTitleCode(), MultilanguageText);
        chartBuilder.SetYAxisMultilanguageTitle(MultilanguageText);

        if TempGenericChartYAxis.Find('-') then begin
            CaptionCode := RequiredMeasureCode();
            repeat
                BuildMultilanguageText(TempGenericChartCaptionsBuf, CaptionCode, MultilanguageText);
                DataMeasureType := GraphType2ChartType(TempGenericChartYAxis."Chart Type");
                DataAggregationType := Aggregation2Operator(TempGenericChartYAxis.Aggregation);
                chartBuilder.AddMeasure(
                  TempGenericChartYAxis."Y-Axis Measure Field ID", TempGenericChartYAxis."Y-Axis Measure Field Name", MultilanguageText, DataMeasureType, DataAggregationType);
                if CaptionCode = RequiredMeasureCode() then
                    CaptionCode := OptionalMeasure1Code()
                else
                    CaptionCode := IncStr(CaptionCode)
            until TempGenericChartYAxis.Next() = 0
        end;

        // Filters:
        if TempGenericChartFilter.Find('-') then
            repeat
                GetFieldColumnNoName(
                  TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartFilter."Filter Field ID", TempGenericChartFilter."Filter Field Name", true);
                if TempGenericChartFilter."Filter Field ID" > 0 then
                    case TempGenericChartSetup."Source Type" of
                        TempGenericChartSetup."Source Type"::Table:
                            chartBuilder.AddTableFilter(TempGenericChartFilter."Filter Field ID", TempGenericChartFilter."Filter Field Name", TempGenericChartFilter."Filter Value");
                        TempGenericChartSetup."Source Type"::Query:
                            chartBuilder.AddQueryFilter(TempGenericChartFilter."Filter Field ID", TempGenericChartFilter."Filter Field Name", TempGenericChartFilter."Filter Value");
                    end;
            until TempGenericChartFilter.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SaveChanges(var Chart: Record Chart; TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary; var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary)
    var
        chartBuilder: DotNet BusinessChartBuilder;
        OutStream: OutStream;
    begin
        chartBuilder := chartBuilder.Empty();
        FillChartHelper(chartBuilder, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter,
          TempGenericChartCaptionsBuf, TempGenericChartMemoBuf);
        Clear(Chart.BLOB);
        Chart.BLOB.CreateOutStream(OutStream);
        CopyStream(OutStream, chartBuilder.GetAsStream());
        Clear(chartBuilder);
    end;

    procedure LookUpObjectId(ObjType: Option " ","Table","Query"; var ObjID: Integer; var ObjName: Text[50])
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        SetObjTypeRange(ObjType, AllObjWithCaption);
        if PAGE.RunModal(PAGE::Objects, AllObjWithCaption) = ACTION::LookupOK then begin
            ObjID := AllObjWithCaption."Object ID";
            ValidateObjectID(ObjType, ObjID, ObjName);
        end;
    end;

    procedure ValidateObjectID(ObjType: Option " ","Table","Query"; var ObjID: Integer; var ObjName: Text[50])
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        ObjName := '';
        if ObjType = ObjType::" " then begin
            ObjID := 0;
            exit;
        end;
        SetObjTypeRange(ObjType, AllObjWithCaption);
        AllObjWithCaption.SetRange("Object ID", ObjID);
        if AllObjWithCaption.FindFirst() then
            ObjName := AllObjWithCaption."Object Name";
    end;

    [Scope('OnPrem')]
    procedure ValidateFieldColumn(TempGenericChartSetup: Record "Generic Chart Setup" temporary; var FieldColumnNo: Integer; FieldColumnName: Text[80]; var FieldCaption: Text[250]; Category: Integer; FilteringLookup: Boolean; var Aggregation: Option "None","Count","Sum","Min","Max",Avg)
    var
        "Field": Record "Field";
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
    begin
        // Category: 0: All, 1: Not integer and decimal, 2: Only integer and decimal
        CheckSourceTypeID(TempGenericChartSetup, true);
        FieldColumnNo := 0;
        FieldCaption := '';
        if FieldColumnName = '' then begin
            Aggregation := Aggregation::None;
            exit;
        end;

        case TempGenericChartSetup."Source Type" of
            TempGenericChartSetup."Source Type"::Table:
                begin
                    Field.SetRange(TableNo, TempGenericChartSetup."Source ID");
                    Field.SetRange(FieldName, FieldColumnName);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    FilterFieldCategory(Field, Category, FilteringLookup);
                    Field.FindFirst();
                    FieldColumnNo := Field."No.";
                end;
            TempGenericChartSetup."Source Type"::Query:
                begin
                    GetQueryColumnList(TempGenericChartQueryColumn, TempGenericChartSetup."Source ID", Category, FilteringLookup);
                    TempGenericChartQueryColumn.SetRange("Query No.", TempGenericChartSetup."Source ID");
                    TempGenericChartQueryColumn.SetRange("Column Name", FieldColumnName);
                    TempGenericChartQueryColumn.FindFirst();
                    FieldColumnNo := TempGenericChartQueryColumn."Query Column No.";
                    FieldColumnName := TempGenericChartQueryColumn."Column Name";
                    Aggregation := TempGenericChartQueryColumn."Aggregation Type";
                end;
        end;
        FieldCaption := FieldColumnName;
    end;

    [Scope('OnPrem')]
    procedure RetrieveFieldColumn(TempGenericChartSetup: Record "Generic Chart Setup" temporary; var No: Integer; var Name: Text[80]; var Capt: Text[250]; Category: Integer; FilteringLookup: Boolean)
    var
        "Field": Record "Field";
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
        FieldSelection: Codeunit "Field Selection";
    begin
        // Category: 0: All, 1: Not integer and decimal, 2: Only integer and decimal
        CheckSourceTypeID(TempGenericChartSetup, true);
        case TempGenericChartSetup."Source Type" of
            TempGenericChartSetup."Source Type"::Table:
                begin
                    Field.SetRange(TableNo, TempGenericChartSetup."Source ID");
                    FilterFieldCategory(Field, Category, FilteringLookup);
                    if FieldSelection.Open(Field) then begin
                        No := Field."No.";
                        Name := Field.FieldName;
                        Capt := Name;
                    end;
                end;
            TempGenericChartSetup."Source Type"::Query:
                begin
                    GetQueryColumnList(TempGenericChartQueryColumn, TempGenericChartSetup."Source ID", Category, FilteringLookup);
                    TempGenericChartQueryColumn.SetRange("Query No.", TempGenericChartSetup."Source ID");
                    if PAGE.RunModal(PAGE::"Generic Chart Query Columns", TempGenericChartQueryColumn) = ACTION::LookupOK then begin
                        No := TempGenericChartQueryColumn."Query Column No.";
                        Name := TempGenericChartQueryColumn."Column Name";
                        Capt := Name;
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure RetrieveFieldColumnIDFromName(ObjType: Option " ","Table","Query"; ObjID: Integer; var No: Integer; Name: Text[50])
    var
        "Field": Record "Field";
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
    begin
        No := 0;
        case ObjType of
            ObjType::Table:
                begin
                    Field.SetRange(TableNo, ObjID);
                    Field.SetRange(FieldName, Name);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    if Field.FindFirst() then
                        No := Field."No.";
                end;
            ObjType::Query:
                begin
                    GetQueryColumnList(TempGenericChartQueryColumn, ObjID, 0, true);
                    TempGenericChartQueryColumn.SetRange("Query No.", ObjID);
                    TempGenericChartQueryColumn.SetRange("Column Name", Name);
                    if TempGenericChartQueryColumn.FindFirst() then
                        No := TempGenericChartQueryColumn."Query Column No.";
                end;
        end;
    end;

    procedure SetObjTypeRange(ObjType: Option " ","Table","Query"; var AllObjWithCaption: Record AllObjWithCaption)
    begin
        Clear(AllObjWithCaption);
        case ObjType of
            ObjType::Table:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            ObjType::Query:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Query);
        end;
    end;

    local procedure ChartType2GraphType(DataMeasureType: DotNet DataMeasureType): Integer
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

    local procedure GraphType2ChartType(GraphType: Integer): Integer
    begin
        // Save function:
        // Aggregation var on page 9183:
        // Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,Pie,Doughnut,Range,Radar,Funnel
        // option in TAB485:
        // Point,1,Bubble,Line,4,StepLine,6,7,8,9,Column,StackedColumn,StackedColumn100,Area,14,StackedArea,StackedArea100,Pie,Doughnut,19,20,Range,22,23,24,Radar,26,27,28,29,30,31,32,Funnel}

        case GraphType of
            0:
                exit(10); // Column
            1:
                exit(0);  // Point
            2:
                exit(3);  // Line
            3:
                exit(11); // ColumnStacked
            4:
                exit(12); // ColumnStacked100
            5:
                exit(13); // Area
            6:
                exit(15); // AreaStacked
            7:
                exit(16); // AreaStacked100
            8:
                exit(5);  // StepLine
            9:
                exit(17); // Pie
            10:
                exit(18); // Doughnut
            11:
                exit(21); // Range
            12:
                exit(25); // Radar
            13:
                exit(33); // Funnel
            else
                exit(GraphType);
        end;
    end;

    local procedure Aggregation2Operator(Aggregation: Integer): Integer
    begin
        // From Rec (BLOB) to XML File - i.e. when saving
        // Aggregation:
        exit(Aggregation);
    end;

    local procedure Operator2Aggregation(Operator: Integer): Integer
    begin
        // Retrieve from XML (BLOB) to rec
        exit(Operator);
    end;

    [Scope('OnPrem')]
    procedure GetQueryColumnList(var TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary; ObjID: Integer; ColFilter: Integer; FilteringLookup: Boolean)
    var
        ApplicationObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        metaData: DotNet QueryMetadataReader;
        inStream: InStream;
    begin
        // Colfilter: = 0: All, 1: Only text etc (X- and Z-Axis), 2: Only decimal and integer (Y-axis)
        Clear(TempGenericChartQueryColumn);
        TempGenericChartQueryColumn.DeleteAll();

        AllObj.Get(AllObj."Object Type"::Query, ObjID);
        if not ApplicationObjectMetadata.Get(AllObj."App Runtime Package ID", ApplicationObjectMetadata."Object Type"::Query, ObjID) then
            exit;
        if not ApplicationObjectMetadata.Metadata.HasValue() then
            exit;
        ApplicationObjectMetadata.CalcFields(Metadata);
        ApplicationObjectMetadata.Metadata.CreateInStream(inStream);

        // Load into Query Metadata Reader and retrieve values
        metaData := metaData.FromStream(inStream);
        LoadQueryColumns(metaData, TempGenericChartQueryColumn, ObjID, ColFilter, FilteringLookup);
    end;

    local procedure FilterFieldCategory(var "Field": Record "Field"; Category: Integer; FilteringLookup: Boolean)
    begin
        case Category of
            0:
                Field.SetRange(Type);
            1, 2:
                Field.SetFilter(Type, TypeFilterText(Category));
        end;
        Field.SetRange(Class);
        if not FilteringLookup then
            Field.SetFilter(Class, '<>%1', Field.Class::FlowFilter);
    end;

    local procedure ValidateChart(TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        DummyAggregation: Option "None","Count","Sum","Min","Max",Avg;
        DummyCaption: Text[250];
        DummyInt: Integer;
    begin
        case TempGenericChartSetup."Source Type" of
            TempGenericChartSetup."Source Type"::Table:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            TempGenericChartSetup."Source Type"::Query:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Query);
        end;
        AllObjWithCaption.SetRange("Object ID", TempGenericChartSetup."Source ID");
        AllObjWithCaption.FindFirst();
        if TempGenericChartYAxis.FindSet() then
            repeat
                ValidateFieldColumn(
                  TempGenericChartSetup, DummyInt, TempGenericChartYAxis."Y-Axis Measure Field Name", DummyCaption, 2, false, DummyAggregation);
            until TempGenericChartYAxis.Next() = 0;
        if TempGenericChartFilter.FindSet() then
            repeat
                ValidateFieldColumn(
                  TempGenericChartSetup, DummyInt, TempGenericChartFilter."Filter Field Name", DummyCaption, 0, true, DummyAggregation);
            until TempGenericChartFilter.Next() = 0;
        ValidateFieldColumn(TempGenericChartSetup, DummyInt, TempGenericChartSetup."X-Axis Field Name", TempGenericChartSetup."X-Axis Title", 0, false, DummyAggregation);
        ValidateFieldColumn(TempGenericChartSetup, DummyInt, TempGenericChartSetup."Z-Axis Field Name", TempGenericChartSetup."Z-Axis Title", 0, false, DummyAggregation);
    end;

    local procedure LoadQueryColumns(var MetaData: DotNet QueryMetadataReader; var TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary; ObjID: Integer; FieldTypeFilter: Integer; FilteringLookup: Boolean)
    var
        FieldParam: Record "Field";
        queryField: DotNet QueryFields;
        i: Integer;
        j: Integer;
        InclInColumns: Boolean;
    begin
        // Field Type:
        // Category:  0: All, 1: Not integer and decimal, 2: Only integer and decimal
        // String,Integer,Decimal,DateTime
        if MetaData.Fields.Count = 0 then
            exit;
        for i := 0 to MetaData.Fields.Count - 1 do begin
            j := 0;
            queryField := MetaData.Fields.Item(i);
            InclInColumns := false;
            if FilteringLookup or not queryField.IsFilterOnly then
                InclInColumns := SetInclInColumns(FieldTypeFilter, queryField.TableNo, queryField.FieldNo, FieldParam);
            if InclInColumns then begin
                Clear(TempGenericChartQueryColumn);
                TempGenericChartQueryColumn."Query No." := ObjID;
                TempGenericChartQueryColumn."Query Column No." := queryField.ColumnId;
                TempGenericChartQueryColumn."Column Name" := queryField.FieldName;
                TempGenericChartQueryColumn.SetAggregationType(queryField.AggregationType);
                TempGenericChartQueryColumn.SetColumnDataType(FieldParam.Type);
                repeat
                    j += 1;
                    TempGenericChartQueryColumn."Entry No." := j;
                until TempGenericChartQueryColumn.Insert();
            end;
        end;
    end;

    procedure CopyChart(var SourceChart: Record Chart; TargetChartID: Code[20]; TargetChartTitle: Text[50])
    var
        TargetChart: Record Chart;
    begin
        Clear(TargetChart);
        TargetChart := SourceChart;
        TargetChart.Validate(ID, TargetChartID);
        if TargetChartTitle <> '' then
            TargetChart.Validate(Name, TargetChartTitle)
        else
            TargetChart.Validate(Name, SourceChart.Name);
        TargetChart.Insert(true);
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
        exit(true);
    end;

    procedure BuildFilterText(var FilterText: Text[250]; Inp: Text[100])
    begin
        if FilterText <> '' then
            AddToFilterText(FilterText, CopyStr(' ; ' + Inp, 1, MaxStrLen(FilterText)))
        else
            AddToFilterText(FilterText, CopyStr(Inp, 1, MaxStrLen(FilterText)));
    end;

    local procedure AddToFilterText(var FText: Text[250]; Inp: Text[100])
    var
        RemLgth: Integer;
    begin
        if StrLen(FText + Inp) <= MaxStrLen(FText) then begin
            FText := FText + Inp;
            exit;
        end;
        RemLgth := MaxStrLen(FText) - StrLen(FText);
        if RemLgth > 3 then
            FText := FText + ',...'
        else
            FText := PadStr(FText, MaxStrLen(FText), '.');
    end;

    procedure FinalizeFilterText(var InTxt: Text[250])
    begin
        if InTxt = '' then
            InTxt := NoFiltersSelectedTxt;
    end;

    [Scope('OnPrem')]
    procedure GetDescription(Chart: Record Chart): Text
    var
        chartBuilder: DotNet BusinessChartBuilder;
    begin
        if not GetChartBuilder(Chart, chartBuilder) then
            exit('');
        exit(chartBuilder.Description);
    end;

    [Scope('OnPrem')]
    procedure ChartCustomization(var TempChart: Record Chart temporary): Boolean
    begin
        TempChart.Insert();
        if NoOfMeasuresApplied(TempChart) > GetMaxNoOfMeasures() then begin
            Message(TooManyMeasuresErr, GetMaxNoOfMeasures());
            exit(false);
        end;
        exit(PAGE.RunModal(PAGE::"Generic Chart Customization", TempChart) = ACTION::LookupOK);
    end;

    local procedure NoOfMeasuresApplied(var TempChart: Record Chart): Integer
    var
        chartBuilder: DotNet BusinessChartBuilder;
    begin
        if not GetChartBuilder(TempChart, chartBuilder) then
            exit(0);
        exit(chartBuilder.MeasureCount);
    end;

    local procedure GetMaxNoOfMeasures(): Integer
    begin
        exit(6); // Max number of measures allowed when using the Chart Design pages 9183, 9188
    end;

    local procedure GetFieldColumnNoName(SourceType: Option " ","Table","Query"; SourceNo: Integer; var FieldColNo: Integer; var FieldColName: Text; FilteringLookup: Boolean)
    var
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
        "Field": Record "Field";
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
                    GetQueryColumnList(TempGenericChartQueryColumn, SourceNo, 0, FilteringLookup);
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

    local procedure GetSourceIDName(SourceType: Option " ","Table","Query"; var SourceID: Integer; var SourceName: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        case SourceType of
            SourceType::Table:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            SourceType::Query:
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Query);
        end;
        if SourceID > 0 then begin
            AllObjWithCaption.SetRange("Object ID", SourceID);
            AllObjWithCaption.FindFirst();
            SourceName := AllObjWithCaption."Object Name";
            exit;
        end;
        if SourceName <> '' then begin
            AllObjWithCaption.SetRange("Object Name", SourceName);
            AllObjWithCaption.FindFirst();
            SourceID := AllObjWithCaption."Object ID";
        end;
    end;

    local procedure BuildTempGenericChartFilter(TempGenericChartSetup: Record "Generic Chart Setup" temporary; var TempGenericChartFilter: Record "Generic Chart Filter" temporary; var chartBuilder: DotNet BusinessChartBuilder; var FilterText: Text[250])
    var
        i: Integer;
    begin
        TempGenericChartFilter.DeleteAll();
        case TempGenericChartSetup."Source Type" of
            TempGenericChartSetup."Source Type"::Table:
                for i := 0 to chartBuilder.TableFilterCount - 1 do begin
                    TempGenericChartFilter.Init();
                    TempGenericChartFilter.ID := TempGenericChartSetup.ID;
                    TempGenericChartFilter."Line No." := i + 1;
                    TempGenericChartFilter."Filter Field ID" := chartBuilder.GetTableFilterFieldId(i);
                    TempGenericChartFilter."Filter Field Name" := chartBuilder.GetTableFilterFieldName(i);
                    GetFieldColumnNoName(
                      TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartFilter."Filter Field ID", TempGenericChartFilter."Filter Field Name", true);
                    TempGenericChartFilter."Filter Value" := chartBuilder.GetTableFilterValue(i);
                    if TempGenericChartFilter."Filter Value" <> '' then
                        BuildFilterText(FilterText,
                          CopyStr(TempGenericChartFilter."Filter Field Name" + ' : ' + TempGenericChartFilter."Filter Value", 1, MaxStrLen(FilterText)));
                    TempGenericChartFilter.Insert();
                end;
            TempGenericChartSetup."Source Type"::Query:
                for i := 0 to chartBuilder.QueryFilterCount - 1 do begin
                    TempGenericChartFilter.Init();
                    TempGenericChartFilter.ID := TempGenericChartSetup.ID;
                    TempGenericChartFilter."Line No." := i + 1;
                    TempGenericChartFilter."Filter Field ID" := chartBuilder.GetQueryFilterFieldId(i);
                    TempGenericChartFilter."Filter Field Name" := chartBuilder.GetQueryFilterFieldName(i);
                    GetFieldColumnNoName(
                      TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartFilter."Filter Field ID", TempGenericChartFilter."Filter Field Name", true);
                    TempGenericChartFilter."Filter Value" := chartBuilder.GetQueryFilterValue(i);
                    if TempGenericChartFilter."Filter Value" <> '' then
                        BuildFilterText(FilterText,
                          CopyStr(TempGenericChartFilter."Filter Field Name" + ' : ' + TempGenericChartFilter."Filter Value", 1, MaxStrLen(FilterText)));
                    TempGenericChartFilter.Insert();
                end;
        end;
    end;

    local procedure SetInclInColumns(FilterType: Integer; TableNumber: Integer; FieldNumber: Integer; var FieldType: Record "Field"): Boolean
    var
        "Field": Record "Field";
    begin
        if FieldNumber < 0 then
            exit(false);
        if FieldNumber = 0 then
            exit(FilterType in [0, 2]);
        // The column method is Count which is a numeral
        Field.SetRange(TableNo, TableNumber);
        Field.SetRange("No.", FieldNumber);
        if FilterType > 0 then
            Field.SetFilter(Type, TypeFilterText(FilterType));
        if Field.FindFirst() then begin
            FieldType.Type := Field.Type;
            exit(true);
        end;
        exit(false);
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

    procedure CheckSourceTypeID(TempGenericChartSetup: Record "Generic Chart Setup" temporary; CheckSourceID: Boolean)
    begin
        if TempGenericChartSetup."Source Type" = TempGenericChartSetup."Source Type"::" " then
            Error(MustSelectFieldErr, TempGenericChartSetup.FieldCaption("Source Type"));
        if CheckSourceID then
            if TempGenericChartSetup."Source ID" = 0 then
                Error(MustSelectFieldErr, TempGenericChartSetup.FieldCaption("Source ID"));
    end;

    [Scope('OnPrem')]
    procedure GetQueryCountColumnName(var TempGenericChartSetup: Record "Generic Chart Setup" temporary): Text[50]
    var
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
    begin
        if TempGenericChartSetup."Source Type" <> TempGenericChartSetup."Source Type"::Query then
            exit('');
        GetQueryColumnList(TempGenericChartQueryColumn, TempGenericChartSetup."Source ID", 0, true);
        TempGenericChartQueryColumn.SetRange("Aggregation Type", TempGenericChartQueryColumn."Aggregation Type"::Count);
        if not TempGenericChartQueryColumn.FindFirst() then
            Error(CountColumnNotFoundErr);
        exit(TempGenericChartQueryColumn."Column Name");
    end;

    [Scope('OnPrem')]
    procedure CheckDataTypeAggregationCompliance(TempGenericChartSetup: Record "Generic Chart Setup" temporary; ColumnName: Text[50]; Aggregation: Option "None","Count","Sum","Min","Max",Avg)
    var
        TempGenericChartQueryColumn: Record "Generic Chart Query Column" temporary;
    begin
        if TempGenericChartSetup."Source Type" <> TempGenericChartSetup."Source Type"::Query then
            exit;
        if ColumnName = '' then
            exit;
        if Aggregation in [Aggregation::None, Aggregation::Count] then
            exit;
        GetQueryColumnList(TempGenericChartQueryColumn, TempGenericChartSetup."Source ID", 0, false);
        TempGenericChartQueryColumn.SetRange("Column Name", ColumnName);
        if not TempGenericChartQueryColumn.FindFirst() then
            exit;
        ValidateCompliance(TempGenericChartQueryColumn."Column Data Type", Aggregation);
    end;

    local procedure ValidateCompliance(ColumnDataType: Option Date,Time,DateFormula,Decimal,Text,"Code",Binary,Boolean,"Integer",Option,BigInteger,DateTime; Aggregation: Option "None","Count","Sum","Min","Max",Avg)
    begin
        if not (Aggregation in [Aggregation::Sum, Aggregation::Min, Aggregation::Max, Aggregation::Avg]) then
            exit;
        if ColumnDataType <> ColumnDataType::Decimal then
            Error(AggregationTypeForDecimalOnlyErr, SelectStr(Aggregation + 1, AggregationTxt));
    end;

    procedure TextMLAssistEdit(var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; CaptionCode: Code[10]): Text[250]
    var
        GenericChartTextEditor: Page "Generic Chart Text Editor";
    begin
        exit(GenericChartTextEditor.AssistEdit(TempGenericChartCaptionsBuf, CaptionCode))
    end;

    procedure MemoMLAssistEdit(var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary; MemoCode: Code[10]): Text
    var
        GenericChartMemoEditor: Page "Generic Chart Memo Editor";
    begin
        exit(GenericChartMemoEditor.AssistEdit(TempGenericChartMemoBuf, MemoCode))
    end;

    local procedure BuildMultilanguageText(var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; CaptionCode: Code[10]; var MultilanguageText: DotNet BusinessChartMultiLanguageText)
    var
        Language: Codeunit Language;
        LanguageId: Integer;
    begin
        MultilanguageText := MultilanguageText.BusinessChartMultiLanguageText();
        TempGenericChartCaptionsBuf.SetRange(Code, CaptionCode);
        if TempGenericChartCaptionsBuf.FindSet() then
            repeat
                LanguageId := Language.GetLanguageId(TempGenericChartCaptionsBuf."Language Code");
                if LanguageId <> 0 then
                    MultilanguageText.SetText(LanguageId, TempGenericChartCaptionsBuf.Caption);
            until TempGenericChartCaptionsBuf.Next() = 0;
        TempGenericChartCaptionsBuf.SetRange(Code)
    end;

    local procedure BuildCaptionBuf(var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; CaptionCode: Code[10]; MultilanguageText: DotNet BusinessChartMultiLanguageText)
    var
        Language: Codeunit Language;
        LanguageCode: Code[10];
        Index: Integer;
    begin
        TempGenericChartCaptionsBuf.SetRange(Code, CaptionCode);
        TempGenericChartCaptionsBuf.DeleteAll();
        TempGenericChartCaptionsBuf.Code := CaptionCode;
        for Index := 0 to MultilanguageText.Count - 1 do begin
            LanguageCode := Language.GetLanguageCode(MultilanguageText.GetWindowsLanguageIdAt(Index));
            if LanguageCode <> '' then begin
                TempGenericChartCaptionsBuf."Language Code" := LanguageCode;
                TempGenericChartCaptionsBuf.Caption := MultilanguageText.GetTextAt(Index);
                if TempGenericChartCaptionsBuf.Insert() then;
            end;
        end;
        TempGenericChartCaptionsBuf.SetRange(Code)
    end;

    local procedure BuildMemoMultilanguageText(var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary; MemoCode: Code[10]; var MultilanguageText: DotNet BusinessChartMultiLanguageText)
    var
        Language: Codeunit Language;
        LanguageId: Integer;
    begin
        MultilanguageText := MultilanguageText.BusinessChartMultiLanguageText();
        TempGenericChartMemoBuf.SetRange(Code, MemoCode);
        if TempGenericChartMemoBuf.FindSet() then
            repeat
                Language.GetLanguageId(TempGenericChartMemoBuf."Language Code");
                if LanguageId <> 0 then
                    MultilanguageText.SetText(LanguageId, TempGenericChartMemoBuf.GetMemoText());
            until TempGenericChartMemoBuf.Next() = 0;
        TempGenericChartMemoBuf.SetRange(Code)
    end;

    local procedure BuildMemoBuf(var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary; MemoCode: Code[10]; MultilanguageText: DotNet BusinessChartMultiLanguageText)
    var
        Language: Codeunit Language;
        LanguageCode: Code[10];
        Index: Integer;
    begin
        TempGenericChartMemoBuf.SetRange(Code, MemoCode);
        TempGenericChartMemoBuf.DeleteAll();
        TempGenericChartMemoBuf.Code := MemoCode;
        for Index := 0 to MultilanguageText.Count - 1 do begin
            LanguageCode := Language.GetLanguageCode(MultilanguageText.GetWindowsLanguageIdAt(Index));
            if LanguageCode <> '' then begin
                TempGenericChartMemoBuf."Language Code" := LanguageCode;
                TempGenericChartMemoBuf.SetMemoText(MultilanguageText.GetTextAt(Index));
                if TempGenericChartMemoBuf.Insert() then;
            end;
        end;
        TempGenericChartMemoBuf.SetRange(Code);
    end;

    procedure GetUserLanguage(): Code[10]
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetUserLanguageCode())
    end;

    procedure DescriptionCode(): Code[10]
    begin
        exit(DescriptionTok)
    end;

    procedure XAxisTitleCode(): Code[10]
    begin
        exit(XAxisTitleTok)
    end;

    procedure YAxisTitleCode(): Code[10]
    begin
        exit(YAxisTitleTok)
    end;

    local procedure ZAxisTitleCode(): Code[10]
    begin
        exit(ZAxisTitleTok)
    end;

    procedure XAxisCaptionCode(): Code[10]
    begin
        exit(XAxisCaptionTok)
    end;

    procedure ZAxisCaptionCode(): Code[10]
    begin
        exit(ZAxisCaptionTok)
    end;

    procedure RequiredMeasureCode(): Code[10]
    begin
        exit(RequiredTok)
    end;

    procedure OptionalMeasure1Code(): Code[10]
    begin
        exit(Optional1Tok)
    end;

    procedure OptionalMeasure2Code(): Code[10]
    begin
        exit(Optional2Tok)
    end;

    procedure OptionalMeasure3Code(): Code[10]
    begin
        exit(Optional3Tok)
    end;

    procedure OptionalMeasure4Code(): Code[10]
    begin
        exit(Optional4Tok)
    end;

    procedure OptionalMeasure5Code(): Code[10]
    begin
        exit(Optional5Tok)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'CustomizeChart', '', false, false)]
    local procedure CustomizeChart(var TempChart: Record Chart temporary; var LookupOK: Boolean)
    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";
    begin
        LookupOK := GenericChartMgt.ChartCustomization(TempChart)
    end;
}

