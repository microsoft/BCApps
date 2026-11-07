namespace System.Visualization;

using System;
using System.Integration;

page 9184 "Generic Chart Type Preview"
{
    Caption = 'Generic Chart Type Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;

    layout
    {
        area(content)
        {
            usercontrol(Chart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(Point: JsonObject)
                begin
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    ChartAddInInitialized := true
                end;

                trigger Refresh()
                begin
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        ChartAddInInitialized := false
    end;

    var
        SampleChartDataTxt: Label 'Sample Chart Data', Comment = 'Sample Chart Data';
        CategoryTxt: Label 'Cat', Comment = 'Cat';
        ChartAddInInitialized: Boolean;

    [Scope('OnPrem')]
    procedure SetChartDefinition(ChartBuilder: DotNet BusinessChartBuilder)
    var
        GenericChartYAxis: Record "Generic Chart Y-Axis";
        ChartDefinition: DotNet BusinessChartData;
        ChartDataTable: DotNet DataTable;
        ChartDataRow: DotNet DataRow;
        DataType: DotNet Type;
        JsonConvert: DotNet JsonConvert;
        BusinessChartAsJson: JsonObject;
        i: Integer;
        j: Integer;
        BusinessChartText: Text;
        MeasureName: Text;
    begin
        if not ChartAddInInitialized then
            exit;

        ChartDefinition := ChartDefinition.BusinessChartData();
        ChartDataTable := ChartDataTable.DataTable(SampleChartDataTxt);
        // chartBuilder -> chartDef
        if ChartBuilder.HasXDimension then begin
            ChartDataTable.Columns.Add(ChartBuilder.XDimensionName, DataType.GetType('System.String'));
            ChartDefinition.XDimension := ChartBuilder.XDimensionName;
        end;

        if ChartBuilder.HasZDimension then begin
            ChartDataTable.Columns.Add(ChartBuilder.ZDimensionName, DataType.GetType('System.String'));
            ChartDefinition.ZDimension := ChartBuilder.ZDimensionName;
        end;

        for i := 0 to ChartBuilder.MeasureCount - 1 do begin
            MeasureName := ChartBuilder.GetMeasureName(i);
            if MeasureName = '' then
                MeasureName := Format(GenericChartYAxis.Aggregation::Count);
            ChartDataTable.Columns.Add(MeasureName, DataType.GetType('System.Decimal'));
            ChartDefinition.AddMeasure(MeasureName, ChartBuilder.GetMeasureChartType(i));
        end;

        for i := 0 to 10 do begin
            ChartDataRow := ChartDataTable.NewRow();
            if ChartBuilder.HasXDimension and (ChartBuilder.XDimensionName <> '') then
                ChartDataRow.Item(ChartBuilder.XDimensionName, CategoryTxt + Format(i));
            if ChartBuilder.HasZDimension and (ChartBuilder.ZDimensionName <> '') then
                ChartDataRow.Item(ChartBuilder.ZDimensionName, CategoryTxt + Format(i));
            for j := 0 to ChartBuilder.MeasureCount - 1 do begin
                MeasureName := ChartBuilder.GetMeasureName(j);
                if MeasureName = '' then
                    MeasureName := Format(GenericChartYAxis.Aggregation::Count);
                ChartDataRow.Item(MeasureName, Random(100));
            end;
            ChartDataTable.Rows.Add(ChartDataRow);
        end;

        ChartDefinition.DataTable := ChartDataTable;
        BusinessChartText := JsonConvert.SerializeObject(ChartDefinition);
        BusinessChartAsJson.ReadFrom(BusinessChartText);

        CurrPage.Chart.Update(BusinessChartAsJson)
    end;
}

