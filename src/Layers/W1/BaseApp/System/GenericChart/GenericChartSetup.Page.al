namespace System.Visualization;

using System;
using System.IO;
using System.Reflection;
using System.Utilities;

page 9183 "Generic Chart Setup"
{
    Caption = 'Generic Chart Setup';
    PageType = Card;
    SourceTable = Chart;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the unique ID of the chart.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the chart.';
                }
                field(ChartExists; Rec.BLOB.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chart Exists';
                    ToolTip = 'Specifies that one or more charts have been created from the generic chart. ';
                    Visible = false;
                }
            }
            group("Data Source")
            {
                Caption = 'Data Source';
                field("Source Type"; TempGenericChartSetup."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Type';
                    ToolTip = 'Specifies the source type for the chart.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CalledFrom: Option "Source Type","Source ID";
                    begin
                        ResetFields(CalledFrom::"Source Type");
                        UpdateChartDefinition();
                        StoreTempXRecValues()
                    end;

                    trigger OnValidate()
                    var
                        CalledFrom: Option "Source Type","Source ID";
                    begin
                        ResetFields(CalledFrom::"Source Type");
                        UpdateChartDefinition();
                        StoreTempXRecValues()
                    end;
                }
                field("Source ID"; TempGenericChartSetup."Source ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source ID';
                    ToolTip = 'Specifies the source ID for the chart.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                        CalledFrom: Option "Source Type","Source ID";
                    begin
                        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, false);
                        GenericChartMgt.LookUpObjectId(
                          TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."Object Name");
                        ResetFields(CalledFrom::"Source ID");
                        GenericChartMgt.ValidateObjectID(
                          TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."Object Name");
                        UpdateChartDefinition();
                        StoreTempXRecValues()
                    end;

                    trigger OnValidate()
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                        CalledFrom: Option "Source Type","Source ID";
                    begin
                        ResetFields(CalledFrom::"Source ID");
                        GenericChartMgt.ValidateObjectID(
                          TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartSetup."Object Name");
                        UpdateChartDefinition();
                        StoreTempXRecValues()
                    end;
                }
                field("Source Name"; TempGenericChartSetup."Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Name';
                    Editable = false;
                    ToolTip = 'Specifies the source name for the chart.';

                    trigger OnValidate()
                    begin
                        UpdateChartDefinition();
                    end;
                }
#pragma warning disable AA0100
                field("TempGenericChartSetup.""Filter Text"""; TempGenericChartSetup."Filter Text")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filters';
                    Editable = false;
                    ToolTip = 'Specifies the field filters which delimit the field values that the chart is based on.';

                    trigger OnAssistEdit()
                    begin
                        ShowChartFiltersPage();
                        CurrPage.Update();
                    end;
                }
            }
            group("Measures (Y-Axis)")
            {
                Caption = 'Measures (Y-Axis)';
                //The GridLayout property is only supported on controls of type Grid
                //GridLayout = Rows;
                grid(Control25)
                {
                    GridLayout = Rows;
                    ShowCaption = false;
                    group("Required Measure")
                    {
                        Caption = 'Required Measure';
                        field(RequiredMeasureColumn; DataColumn[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Data Column';
                            ColumnSpan = 1;
                            Editable = DataColumn1Enabled;
                            Enabled = DataColumn1Enabled;
                            RowSpan = 1;
                            ToolTip = 'Specifies the field or query column that the y-axis is based on. The list of values that appears when you choose Data Column field is filtered by the ID of the data source that you select on the Data Source FastTab.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[1], DummyCaption, 2, false);
                                ValidateDataColumn(1);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(1);
                            end;
                        }
                        field(RequiredMeasureAggregation; Aggregation[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aggregation';
                            ColumnSpan = 1;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            RowSpan = 1;
                            ToolTip = 'Specifies how data on the y-axis is aggregated, such as by the sum or by the maximum values.';

                            trigger OnValidate()
                            begin
                                CheckAggregation(1);
                                UpdateChartDefinition();
                            end;
                        }
                        field(RequiredMeasureType; ChartType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Graph Type';
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,Pie,Doughnut,Range,Radar,Funnel';
                            ToolTip = 'Specifies how data is shown graphically in the chart, such as column, line, or pie.';

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(RequiredMeasureCaption; MeasureCaption[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Data Point Label';
                            ColumnSpan = 1;
                            Editable = DataColumn1Enabled;
                            Enabled = DataColumn1Enabled;
                            RowSpan = 1;
                            ToolTip = 'Specifies the text that describes the selected y-axis value in a tooltip when you hover over a data point. The data point label is shown in front of the data value.';

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[1] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.RequiredMeasureCode());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.RequiredMeasureCode(), GenericChartMgt.GetUserLanguage(), MeasureCaption[1]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                    group("Optional Measure 1")
                    {
                        Caption = 'Optional Measure';
                        field(OptionalMeasureColumn1; DataColumn[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn2Enabled;
                            ShowCaption = false;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[2], DummyCaption, 2, false);
                                ValidateDataColumn(2);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(2);
                            end;
                        }
                        field(OptionalMeasureAggregation1; Aggregation[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                CheckAggregation(2);
                                UpdateChartDefinition();
                            end;
                        }
                        field(OptionalMeasureType1; ChartTypeReduced[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,,,Range';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(OptionalMeasureCaption1; MeasureCaption[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn2Enabled;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[2] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.OptionalMeasure1Code());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.OptionalMeasure1Code(), GenericChartMgt.GetUserLanguage(), MeasureCaption[2]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                    group("Optional Measure 2")
                    {
                        Caption = 'Optional Measure';
                        field(OptionalMeasureColumn2; DataColumn[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn3Enabled;
                            ShowCaption = false;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[3], DummyCaption, 2, false);
                                ValidateDataColumn(3);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(3);
                            end;
                        }
                        field(OptionalMeasureAggregation2; Aggregation[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                CheckAggregation(3);
                                UpdateChartDefinition();
                            end;
                        }
                        field(OptionalMeasureType2; ChartTypeReduced[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,,,Range';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(OptionalMeasureCaption2; MeasureCaption[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn3Enabled;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[3] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.OptionalMeasure2Code());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.OptionalMeasure2Code(), GenericChartMgt.GetUserLanguage(), MeasureCaption[3]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                    group("Optional Measure 3")
                    {
                        Caption = 'Optional Measure';
                        field(OptionalMeasureColumn3; DataColumn[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn4Enabled;
                            ShowCaption = false;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[4], DummyCaption, 2, false);
                                ValidateDataColumn(4);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(4);
                            end;
                        }
                        field(OptionalMeasureAggregation3; Aggregation[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                CheckAggregation(4);
                                UpdateChartDefinition();
                            end;
                        }
                        field(OptionalMeasureType3; ChartTypeReduced[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,,,Range';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(OptionalMeasureCaption3; MeasureCaption[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn4Enabled;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[4] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.OptionalMeasure3Code());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.OptionalMeasure3Code(), GenericChartMgt.GetUserLanguage(), MeasureCaption[4]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                    group("Optional Measure 4")
                    {
                        Caption = 'Optional Measure';
                        field(OptionalMeasureColumn4; DataColumn[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn5Enabled;
                            ShowCaption = false;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[5], DummyCaption, 2, false);
                                ValidateDataColumn(5);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(5);
                            end;
                        }
                        field(OptionalMeasureAggregation4; Aggregation[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                CheckAggregation(5);
                                UpdateChartDefinition();
                            end;
                        }
                        field(OptionalMeasureType4; ChartTypeReduced[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,,,Range';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(OptionalMeasureCaption4; MeasureCaption[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn5Enabled;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[5] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.OptionalMeasure4Code());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.OptionalMeasure4Code(), GenericChartMgt.GetUserLanguage(), MeasureCaption[5]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                    group("Optional Measure 5")
                    {
                        Caption = 'Optional Measure';
                        field(OptionalMeasureColumn5; DataColumn[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn6Enabled;
                            ShowCaption = false;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[6], DummyCaption, 2, false);
                                ValidateDataColumn(6);
                            end;

                            trigger OnValidate()
                            begin
                                ValidateDataColumn(6);
                            end;
                        }
                        field(OptionalMeasureAggregation5; Aggregation[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                CheckAggregation(6);
                                UpdateChartDefinition();
                            end;
                        }
                        field(OptionalMeasureType5; ChartTypeReduced[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled;
                            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,,,Range';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                UpdateChartDefinition();
                                EnableControls();
                            end;
                        }
                        field(OptionalMeasureCaption5; MeasureCaption[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = OptionalMeasuresEnabled;
                            Enabled = OptionalMeasuresEnabled and DataColumn6Enabled;
                            ShowCaption = false;

                            trigger OnAssistEdit()
                            begin
                                MeasureCaption[6] := GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.OptionalMeasure5Code());
                                UpdateChartDefinition();
                            end;

                            trigger OnValidate()
                            begin
                                TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.OptionalMeasure5Code(), GenericChartMgt.GetUserLanguage(), MeasureCaption[6]);
                                UpdateChartDefinition();
                            end;
                        }
                    }
                }
                field("Y-Axis Title"; TempGenericChartSetup."Y-Axis Title")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Y-Axis Title';
                    ToolTip = 'Specifies the text that is shown next to the y-axis on the generic chart. To specify y-axis titles in different languages, choose the AssistEdit button to open the Generic Chart Text Editor window.';

                    trigger OnAssistEdit()
                    begin
                        TempGenericChartSetup."Y-Axis Title" :=
                          GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.YAxisTitleCode());
                        UpdateChartDefinition();
                    end;

                    trigger OnValidate()
                    begin
                        TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.YAxisTitleCode(), GenericChartMgt.GetUserLanguage(),
                          TempGenericChartSetup."Y-Axis Title");
                        UpdateChartDefinition();
                    end;
                }
                field("Show Y-Axis Title"; TempGenericChartSetup."Y-Axis Show Title")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Y-Axis Title';
                    ToolTip = 'Specifies if the value in the Y-Axis Title field is shown on the generic chart.';

                    trigger OnValidate()
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                    begin
                        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, true);
                        UpdateChartDefinition();
                    end;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions (X- and Z-Axes)';
                field("X-Axis Field"; TempGenericChartSetup."X-Axis Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'X-Axis Field';
                    ToolTip = 'Specifies the field in the source object that is shown on the x-axis of the generic chart. The text is shown as a tooltip when you hover over the data element on the chart.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                    begin
                        GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, TempGenericChartSetup."X-Axis Field ID", TempGenericChartSetup."X-Axis Field Name", TempGenericChartSetup."X-Axis Title", 0, false);
                        TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.XAxisTitleCode(), GenericChartMgt.GetUserLanguage(),
                          TempGenericChartSetup."X-Axis Title");
                        ValidateDimension(1);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateDimension(1);
                    end;
                }
                field("X-Axis Title"; TempGenericChartSetup."X-Axis Title")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'X-Axis Title';
                    ToolTip = 'Specifies the text that describes the data that is shown on the x-axis. The text is shown as a tooltip when you hover over the data element on the chart. To specify x-axis titles in different languages, choose the AssistEdit button to open the Generic Chart Text Editor window.';

                    trigger OnAssistEdit()
                    begin
                        TempGenericChartSetup."X-Axis Title" :=
                          GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.XAxisTitleCode());
                        UpdateChartDefinition();
                    end;

                    trigger OnValidate()
                    begin
                        TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.XAxisTitleCode(), GenericChartMgt.GetUserLanguage(),
                          TempGenericChartSetup."X-Axis Title");
                        UpdateChartDefinition();
                    end;
                }
                field("Show X-Axis Title"; TempGenericChartSetup."X-Axis Show Title")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show X-Axis Title';
                    ToolTip = 'Specifies if the value in the X-Axis Title field is shown on the generic chart.';

                    trigger OnValidate()
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                    begin
                        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, true);
                        UpdateChartDefinition();
                    end;
                }
                field("Data Point X Label"; TempGenericChartSetup."X-Axis Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Point X Label';
                    ToolTip = 'Specifies the text describes the selected x-axis value in a tooltip when you hover over a data point. The data point label is shown in front of the data value.';

                    trigger OnAssistEdit()
                    begin
                        TempGenericChartSetup."X-Axis Field Caption" :=
                          GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.XAxisCaptionCode());
                        UpdateChartDefinition();
                    end;

                    trigger OnValidate()
                    begin
                        TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.XAxisCaptionCode(), GenericChartMgt.GetUserLanguage(),
                          TempGenericChartSetup."X-Axis Field Caption");
                        UpdateChartDefinition();
                    end;
                }
                field("Z-Axis Field"; TempGenericChartSetup."Z-Axis Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Z-Axis Field';
                    Editable = ZAxisEnabled;
                    Enabled = ZAxisEnabled;
                    ToolTip = 'Specifies the field in the source object that is shown on the z-axis of the generic chart.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenericChartMgt: Codeunit "Generic Chart Mgt";
                    begin
                        GenericChartMgt.RetrieveFieldColumn(TempGenericChartSetup, TempGenericChartSetup."Z-Axis Field ID", TempGenericChartSetup."Z-Axis Field Name", TempGenericChartSetup."Z-Axis Title", 0, false);
                        ValidateDimension(2);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateDimension(2);
                    end;
                }
                field("Data Point Z Label"; TempGenericChartSetup."Z-Axis Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Point Z Label';
                    ToolTip = 'Specifies the text that describes the z-axis value in a tooltip when you hover over a data point. The data point label is shown in front of the data value.';

                    trigger OnAssistEdit()
                    begin
                        TempGenericChartSetup."Z-Axis Field Caption" :=
                          GenericChartMgt.TextMLAssistEdit(TempGenericChartCaptionsBuf, GenericChartMgt.ZAxisCaptionCode());
                        UpdateChartDefinition();
                    end;

                    trigger OnValidate()
                    begin
                        TempGenericChartCaptionsBuf.SetCaption(GenericChartMgt.ZAxisCaptionCode(), GenericChartMgt.GetUserLanguage(),
                          TempGenericChartSetup."Z-Axis Field Caption");
                        UpdateChartDefinition();
                    end;
                }
            }
            group("Chart Description")
            {
                Caption = 'Chart Description';
                field(Description; ChartDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = TitleEnabled;
                    MultiLine = true;
                    ToolTip = 'Specifies a description of the generic chart.';

                    trigger OnAssistEdit()
                    begin
                        ChartDescription := GenericChartMgt.MemoMLAssistEdit(TempGenericChartMemoBuf, GenericChartMgt.DescriptionCode());
                        UpdateChartDefinition();
                    end;

                    trigger OnValidate()
                    begin
                        TempGenericChartMemoBuf.SetMemo(GenericChartMgt.DescriptionCode(), GenericChartMgt.GetUserLanguage(), ChartDescription);
                        UpdateChartDefinition();
                    end;
                }
            }
            part(PreviewPart; "Generic Chart Type Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview Part';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Import Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Chart';
                Ellipsis = true;
                Image = Import;
                ToolTip = 'Import a generic chart in XML format.';

                trigger OnAction()
                begin
                    ImportChartDefinition();
                end;
            }
            action("E&xport Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E&xport Chart';
                Ellipsis = true;
                Image = Export;
                ToolTip = 'Export a generic chart in XML format. You can rename the file, modify the chart definition using an XML editor, and then import the new chart into another client.';

                trigger OnAction()
                begin
                    ExportChartDefinition();
                end;
            }
            action("Copy Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Chart';
                Ellipsis = true;
                Image = Copy;
                ToolTip = 'Copy an existing chart to create a new generic chart.';

                trigger OnAction()
                var
                    CopyGenericChart: Page "Copy Generic Chart";
                begin
                    CopyGenericChart.SetSourceChart(Rec);
                    CopyGenericChart.RunModal();
                end;
            }
        }
        area(navigation)
        {
            action(Filters)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Filters';
                Image = EditFilter;
                ToolTip = 'Filter on the generic charts.';

                trigger OnAction()
                begin
                    ShowChartFiltersPage();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Import Chart_Promoted"; "Import Chart")
                {
                }
                actionref("E&xport Chart_Promoted"; "E&xport Chart")
                {
                }
                actionref("Copy Chart_Promoted"; "Copy Chart")
                {
                }
                actionref(Filters_Promoted; Filters)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetFieldValues();
        EnableControls();
    end;

    var
        TempGenericChartSetup: Record "Generic Chart Setup" temporary;
        TempGenericChartFilter: Record "Generic Chart Filter" temporary;
        TempGenericChartYAxis: Record "Generic Chart Y-Axis" temporary;
        TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary;
        TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary;
        GenericChartMgt: Codeunit "Generic Chart Mgt";
        DataColumn: array[6] of Text[50];
        MeasureCaption: array[6] of Text[250];
        Aggregation: array[6] of Option "None","Count","Sum","Min","Max",Avg;
        ChartType: Option Column,Point,Line,ColumnStacked,ColumnStacked100,"Area",AreaStacked,AreaStacked100,StepLine,Pie,Doughnut,Range,Radar,Funnel;
        ChartTypeReduced: array[6] of Option Column,Point,Line,ColumnStacked,ColumnStacked100,"Area",AreaStacked,AreaStacked100,StepLine,,,Range;
        ChartDescription: Text;
        xRecSourceType: Option " ","Table","Query";
        xRecSourceID: Integer;
        DummyInt: Integer;
        DummyCaption: Text[50];
#pragma warning disable AA0470
        ResetFieldsQst: Label 'All fields will be reset. Are you sure that you want to change the %1?';
#pragma warning restore AA0470
        OptionalMeasuresEnabled: Boolean;
#pragma warning disable AA0470
        FieldAlreadyAssignedErr: Label 'Field %1 is already assigned to a measure or dimension. Select a different field.';
        ReplaceChartDefinitionQst: Label 'Do you want to replace the existing definition for %1 %2?', Comment = 'Do you want to replace the existing definition for Chart 36-06?';
#pragma warning restore AA0470
        DataColumn1Enabled: Boolean;
        DataColumn2Enabled: Boolean;
        DataColumn3Enabled: Boolean;
        DataColumn4Enabled: Boolean;
        DataColumn5Enabled: Boolean;
        DataColumn6Enabled: Boolean;
        ZAxisEnabled: Boolean;
        OnlyOneCountAggregationErr: Label 'You can only specify one Measure with aggregation type Count.';
        AggregationCountChangeQst: Label 'If you select Aggregation Count, the Data Column will be cleared for this measure. Do you want to continue?';
        TitleEnabled: Boolean;

    local procedure SetFieldValues()
    begin
        ClearAllVariables();
        GenericChartMgt.RetrieveXML(
          Rec, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartCaptionsBuf, TempGenericChartMemoBuf, TempGenericChartFilter);
        ChartDescription := TempGenericChartMemoBuf.GetMemo(GenericChartMgt.DescriptionCode(), GenericChartMgt.GetUserLanguage());
        TempGenericChartSetup."Y-Axis Title" :=
          TempGenericChartCaptionsBuf.GetCaption(GenericChartMgt.YAxisTitleCode(), GenericChartMgt.GetUserLanguage());
        TempGenericChartSetup."X-Axis Field Caption" :=
          TempGenericChartCaptionsBuf.GetCaption(GenericChartMgt.XAxisCaptionCode(), GenericChartMgt.GetUserLanguage());
        TempGenericChartSetup."X-Axis Title" :=
          TempGenericChartCaptionsBuf.GetCaption(GenericChartMgt.XAxisTitleCode(), GenericChartMgt.GetUserLanguage());
        TempGenericChartSetup."Z-Axis Field Caption" :=
          TempGenericChartCaptionsBuf.GetCaption(GenericChartMgt.ZAxisCaptionCode(), GenericChartMgt.GetUserLanguage());
        TempGenericChartSetup.Insert();
        StoreTempXRecValues();
        FillMatrixWhenOpenPage();
        UpdateTempGenericChartYAXis();
        RefreshPreview();
    end;

    local procedure ValidateDataColumn(Index: Integer)
    var
        FieldAlreadyExists: Boolean;
        i: Integer;
    begin
        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, true);
        for i := 1 to ArrayLen(DataColumn) do
            if (DataColumn[i] <> '') and (Index <> i) then
                FieldAlreadyExists := (DataColumn[Index] = DataColumn[i]) or FieldAlreadyExists;
        if FieldAlreadyExists then
            Error(FieldAlreadyAssignedErr, DataColumn[Index]);

        GenericChartMgt.CheckDataTypeAggregationCompliance(TempGenericChartSetup, DataColumn[Index], Aggregation[Index]);
        GenericChartMgt.ValidateFieldColumn(TempGenericChartSetup, DummyInt, DataColumn[Index], DummyCaption, 2, false, Aggregation[Index]);
        UpdateChartDefinition();
        EnableControls();
    end;

    local procedure ValidateDimension(Index: Integer)
    var
        DummyAggregation: Option "None","Count","Sum","Min","Max",Avg;
    begin
        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, true);
        if (TempGenericChartSetup."X-Axis Field Name" <> '') and (TempGenericChartSetup."Z-Axis Field Name" <> '') and (TempGenericChartSetup."X-Axis Field Name" = TempGenericChartSetup."Z-Axis Field Name") then
            Error(FieldAlreadyAssignedErr, DataColumn[Index]);
        case Index of
            1:
                GenericChartMgt.ValidateFieldColumn(
                  TempGenericChartSetup, TempGenericChartSetup."X-Axis Field ID", TempGenericChartSetup."X-Axis Field Name", TempGenericChartSetup."X-Axis Title", 0, false, DummyAggregation);
            2:
                GenericChartMgt.ValidateFieldColumn(
                  TempGenericChartSetup, TempGenericChartSetup."Z-Axis Field ID", TempGenericChartSetup."Z-Axis Field Name", TempGenericChartSetup."Z-Axis Title", 0, false, DummyAggregation);
        end;
        UpdateChartDefinition();
        EnableControls();
    end;

    local procedure UpdateTempGenericChartYAXis()
    var
        i: Integer;
        "Count": Integer;
    begin
        TempGenericChartYAxis.DeleteAll();

        if ChartCapableOfOptionalMeasures() then
            Count := ArrayLen(DataColumn)
        else
            Count := 1;

        for i := 1 to Count do
            if AddYAxisMeasure(i) then begin
                Clear(TempGenericChartYAxis);
                TempGenericChartYAxis.ID := Rec.ID;
                TempGenericChartYAxis."Line No." := i * 10000;
                TempGenericChartYAxis."Y-Axis Measure Field Name" := DataColumn[i];
                GenericChartMgt.RetrieveFieldColumnIDFromName(
                  TempGenericChartSetup."Source Type", TempGenericChartSetup."Source ID", TempGenericChartYAxis."Y-Axis Measure Field ID",
                  DataColumn[i]);
                TempGenericChartYAxis."Y-Axis Measure Field Caption" := MeasureCaption[i];
                TempGenericChartYAxis.Aggregation := Aggregation[i];
                if i = 1 then
                    TempGenericChartYAxis."Chart Type" := ChartType
                else
                    TempGenericChartYAxis."Chart Type" := ChartTypeReduced[i];
                TempGenericChartYAxis.Insert();
            end;
    end;

    local procedure FillMatrixWhenOpenPage()
    var
        i: Integer;
        CurrentCaptionCode: Code[10];
    begin
        Clear(DataColumn);
        Clear(MeasureCaption);
        Clear(Aggregation);
        Clear(ChartType);

        i := 0;
        if TempGenericChartYAxis.FindSet() then begin
            CurrentCaptionCode := GenericChartMgt.RequiredMeasureCode();
            repeat
                i += 1;
                DataColumn[i] := TempGenericChartYAxis."Y-Axis Measure Field Name";
                MeasureCaption[i] := TempGenericChartCaptionsBuf.GetCaption(CurrentCaptionCode, GenericChartMgt.GetUserLanguage());
                Aggregation[i] := TempGenericChartYAxis.Aggregation;
                if i = 1 then
                    ChartType := TempGenericChartYAxis."Chart Type"
                else
                    ChartTypeReduced[i] := TempGenericChartYAxis."Chart Type";

                if CurrentCaptionCode = GenericChartMgt.RequiredMeasureCode() then
                    CurrentCaptionCode := GenericChartMgt.OptionalMeasure1Code()
                else
                    CurrentCaptionCode := IncStr(CurrentCaptionCode)
            until TempGenericChartYAxis.Next() = 0;
        end
    end;

    local procedure UpdateChartDefinition()
    begin
        if ChartDefinitionCreationIsPossible() then begin
            UpdateTempGenericChartYAXis();
            GenericChartMgt.SaveChanges(Rec, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter,
              TempGenericChartCaptionsBuf, TempGenericChartMemoBuf);
        end;
        EnableControls();
        RefreshPreview();
    end;

    local procedure ChartDefinitionCreationIsPossible(): Boolean
    begin
        exit((TempGenericChartSetup."Source Type" <> TempGenericChartSetup."Source Type"::" ") and (TempGenericChartSetup."Source ID" <> 0));
    end;

    local procedure RefreshPreview()
    var
        chartBuilder: DotNet BusinessChartBuilder;
    begin
        if ChartDefinitionCreationIsPossible() then begin
            chartBuilder := chartBuilder.Empty();
            GenericChartMgt.FillChartHelper(chartBuilder, TempGenericChartSetup, TempGenericChartYAxis, TempGenericChartFilter,
              TempGenericChartCaptionsBuf, TempGenericChartMemoBuf);

            CurrPage.PreviewPart.PAGE.SetChartDefinition(chartBuilder);
        end;
    end;

    local procedure ShowChartFiltersPage()
    var
        TempGenericChartFilter2: Record "Generic Chart Filter" temporary;
        GenericChartFiltersPage: Page "Generic Chart Filters";
        FilterText: Text[250];
    begin
        GenericChartMgt.CheckSourceTypeID(TempGenericChartSetup, true);
        GenericChartFiltersPage.SetTempGenericChart(TempGenericChartSetup);
        GenericChartFiltersPage.SetFilters(TempGenericChartFilter);
        GenericChartFiltersPage.SetTableView(TempGenericChartFilter);
        Commit();
        GenericChartFiltersPage.RunModal();
        TempGenericChartFilter.DeleteAll();
        Clear(FilterText);
        GenericChartFiltersPage.GetFilters(TempGenericChartFilter2);
        if TempGenericChartFilter2.FindSet() then
            repeat
                TempGenericChartFilter := TempGenericChartFilter2;
                TempGenericChartFilter.Insert();
                if TempGenericChartFilter."Filter Value" <> '' then
                    GenericChartMgt.BuildFilterText(FilterText,
                      CopyStr(
                        TempGenericChartFilter."Filter Field Name" + ' : ' + TempGenericChartFilter."Filter Value", 1, MaxStrLen(FilterText)));
            until TempGenericChartFilter2.Next() = 0;
        GenericChartMgt.FinalizeFilterText(FilterText);
        TempGenericChartSetup."Filter Text" := FilterText;
        if TempGenericChartSetup.Modify() then;
        UpdateChartDefinition();
    end;

    local procedure ResetFields(CalledFrom: Option "Source Type","Source ID")
    var
        ID: Code[20];
        SourceType: Option;
        SourceID: Integer;
    begin
        ID := TempGenericChartSetup.ID;
        SourceType := TempGenericChartSetup."Source Type";
        SourceID := TempGenericChartSetup."Source ID";
        case CalledFrom of
            CalledFrom::"Source Type":
                begin
                    if TempGenericChartSetup."Source Type" = xRecSourceType then
                        exit;
                    if xRecSourceType <> xRecSourceType::" " then
                        if not Confirm(ResetFieldsQst, true, TempGenericChartSetup.FieldCaption("Source Type")) then
                            Error('');
                end;
            CalledFrom::"Source ID":
                begin
                    if TempGenericChartSetup."Source ID" = xRecSourceID then
                        exit;
                    if xRecSourceID <> 0 then
                        if not Confirm(ResetFieldsQst, true, TempGenericChartSetup.FieldCaption("Source ID")) then
                            Error('');
                end;
        end;
        ClearAllVariables();
        TempGenericChartSetup.ID := ID;
        TempGenericChartSetup."Source Type" := SourceType;
        if CalledFrom = CalledFrom::"Source ID" then
            TempGenericChartSetup."Source ID" := SourceID;
    end;

    local procedure ClearAllVariables()
    begin
        TempGenericChartSetup.DeleteAll();
        TempGenericChartFilter.DeleteAll();
        TempGenericChartYAxis.DeleteAll();
        TempGenericChartCaptionsBuf.DeleteAll();
        TempGenericChartMemoBuf.DeleteAll();

        Clear(TempGenericChartFilter);
        Clear(TempGenericChartYAxis);
        Clear(TempGenericChartSetup);
        Clear(TempGenericChartCaptionsBuf);
        Clear(TempGenericChartMemoBuf);
        Clear(GenericChartMgt);
        Clear(DataColumn);
        Clear(MeasureCaption);
        Clear(Aggregation);
        Clear(ChartType);
        Clear(ChartTypeReduced);
        Clear(DummyInt);
        Clear(DummyCaption);
    end;

    local procedure ChartCapableOfOptionalMeasures(): Boolean
    begin
        exit(not (ChartType in [ChartType::Pie, ChartType::Doughnut, ChartType::Funnel, ChartType::Radar]));
    end;

    local procedure StoreTempXRecValues()
    begin
        xRecSourceType := TempGenericChartSetup."Source Type";
        xRecSourceID := TempGenericChartSetup."Source ID";
    end;

    local procedure ImportChartDefinition()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        if FileMgt.BLOBImport(TempBlob, '*.xml') = '' then
            exit;
        if Rec.BLOB.HasValue() then
            if not Confirm(ReplaceChartDefinitionQst, false, Rec.TableCaption(), Rec.ID) then
                exit;

        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, Rec.FieldNo(BLOB));
        RecordRef.SetTable(Rec);
        CurrPage.SaveRecord();
    end;

    local procedure ExportChartDefinition()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        TempBlob.FromRecord(Rec, Rec.FieldNo(BLOB));
        if TempBlob.HasValue() then
            FileMgt.BLOBExport(TempBlob, '*.xml', true);
    end;

    local procedure EnableControls()
    begin
        OptionalMeasuresEnabled := ChartCapableOfOptionalMeasures() and (TempGenericChartSetup."Z-Axis Field Name" = '');
        ZAxisEnabled :=
          ChartCapableOfOptionalMeasures() and
          (DataColumn[2] = '') and (DataColumn[3] = '') and (DataColumn[4] = '') and (DataColumn[5] = '') and (DataColumn[6] = '');
        TitleEnabled := ChartDefinitionCreationIsPossible();
        DataColumn1Enabled := Aggregation[1] <> Aggregation[1] ::Count;
        DataColumn2Enabled := Aggregation[2] <> Aggregation[2] ::Count;
        DataColumn3Enabled := Aggregation[3] <> Aggregation[3] ::Count;
        DataColumn4Enabled := Aggregation[4] <> Aggregation[4] ::Count;
        DataColumn5Enabled := Aggregation[5] <> Aggregation[5] ::Count;
        DataColumn6Enabled := Aggregation[6] <> Aggregation[6] ::Count;
    end;

    local procedure AddYAxisMeasure(index: Integer): Boolean
    begin
        if Aggregation[index] = Aggregation[index] ::Count then
            exit(true);
        exit(DataColumn[index] <> '');
    end;

    local procedure CheckAggregation(index: Integer)
    var
        FieldOfTypeCountAlreadyExists: Boolean;
        i: Integer;
        CountColumnName: Text[50];
        ReplaceDataColumn: Boolean;
    begin
        for i := 1 to ArrayLen(Aggregation) do
            if (Aggregation[i] = Aggregation[i] ::Count) and (index <> i) then
                FieldOfTypeCountAlreadyExists := (Aggregation[index] = Aggregation[i]) or FieldOfTypeCountAlreadyExists;

        if FieldOfTypeCountAlreadyExists then
            Error(OnlyOneCountAggregationErr);

        GenericChartMgt.CheckDataTypeAggregationCompliance(TempGenericChartSetup, DataColumn[index], Aggregation[index]);
        if Aggregation[index] = Aggregation[index] ::Count then begin
            CountColumnName := GenericChartMgt.GetQueryCountColumnName(TempGenericChartSetup);
            if DataColumn[index] <> CountColumnName then begin
                ReplaceDataColumn := true;
                if DataColumn[index] <> '' then
                    ReplaceDataColumn := Confirm(AggregationCountChangeQst, false);
                if ReplaceDataColumn then
                    DataColumn[index] := CountColumnName
                else
                    Error('');
            end;
        end;
    end;
}

