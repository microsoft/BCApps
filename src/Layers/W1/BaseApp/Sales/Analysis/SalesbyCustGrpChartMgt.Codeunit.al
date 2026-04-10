// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Sales.Customer;
using System.Visualization;

/// <summary>
/// Manages the sales by customer group chart including data calculation and drill-down operations.
/// </summary>
codeunit 1319 "Sales by Cust. Grp. Chart Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        SalesByCustGrpChartSetup: Record "Sales by Cust. Grp.Chart Setup";
        TotalSalesLCYTxt: Label 'Total Sales (LCY)';

    /// <summary>
    /// Initializes the chart setup for the current user when the page opens.
    /// </summary>
    procedure OnInitPage()
    begin
        GetChartSetupForCurrentUser();
    end;

    /// <summary>
    /// Updates the chart data with sales amounts grouped by customer posting group.
    /// </summary>
    /// <param name="BusChartBuf">The business chart buffer to populate with sales data.</param>
    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        NoOfPeriods: Integer;
        ToDate: Date;
        FromDate: Date;
        PeriodNo: Integer;
    begin
        GetChartSetupForCurrentUser();

        NoOfPeriods := 5;
        BusChartBuf.Initialize();
        BusChartBuf."Period Length" := SalesByCustGrpChartSetup."Period Length";
        BusChartBuf."Period Filter Start Date" := SalesByCustGrpChartSetup."Start Date";

        FromDate := BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date");
        for PeriodNo := 1 to NoOfPeriods do begin
            ToDate := BusChartBuf.CalcToDate(FromDate);
            FromDate := CalcDate('<1D>', ToDate);
        end;
        BusChartBuf."Period Filter End Date" := ToDate;

        BusChartBuf.SetPeriodXAxis();
        BusChartBuf.AddPeriods(BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date"), ToDate);

        CalcCustSales(BusChartBuf, NoOfPeriods);
    end;

    /// <summary>
    /// Opens the customer list filtered by the selected chart data point.
    /// </summary>
    /// <param name="BusChartBuf">The business chart buffer containing drill-down context.</param>
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        Cust: Record Customer;
        ToDate: Date;
        FromDate: Date;
        MeasureValueString: Text;
    begin
        GetChartSetupForCurrentUser();

        BusChartBuf."Period Length" := SalesByCustGrpChartSetup."Period Length";
        ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
        FromDate := BusChartBuf.CalcFromDate(ToDate);
        MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");

        if MeasureValueString <> '' then
            Cust.SetRange("Customer Posting Group", MeasureValueString);
        Cust.SetRange("Date Filter", FromDate, ToDate);
        PAGE.Run(PAGE::"Customer List", Cust);
    end;

    local procedure CalcCustSales(var BusChartBuf: Record "Business Chart Buffer"; NoOfPeriods: Decimal)
    var
        ChartQuery: Query "Sales by Cust. Grp. Chart Mgt.";
        TotalSalesValue: Decimal;
        FromDate: Date;
        ToDate: Date;
        PeriodNo: Integer;
    begin
        BusChartBuf.AddDecimalMeasure(TotalSalesLCYTxt, '', BusChartBuf."Chart Type"::Line);

        FromDate := BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date");
        for PeriodNo := 1 to NoOfPeriods do begin
            ToDate := BusChartBuf.CalcToDate(FromDate);
            TotalSalesValue := 0;

            ChartQuery.SetRange(Date_Filter, FromDate, ToDate);
            ChartQuery.Open();

            if ChartQuery.Read() then
                repeat
                    if PeriodNo = 1 then
                        BusChartBuf.AddDecimalMeasure(ChartQuery.Code, ChartQuery.Code, BusChartBuf."Chart Type"::Column);
                    BusChartBuf.SetValue(ChartQuery.Code, PeriodNo - 1, ChartQuery.Sales__LCY_);

                    TotalSalesValue += ChartQuery.Sales__LCY_;
                until not ChartQuery.Read()
            else begin
                BusChartBuf.Initialize();
                exit;
            end;

            BusChartBuf.SetValue(TotalSalesLCYTxt, PeriodNo - 1, TotalSalesValue);
            FromDate := CalcDate('<1D>', ToDate);
        end;
    end;

    local procedure GetChartSetupForCurrentUser()
    begin
        if SalesByCustGrpChartSetup.Get(UserId) then
            exit;
        SalesByCustGrpChartSetup.Init();
        SalesByCustGrpChartSetup."User ID" := UserId();
        SalesByCustGrpChartSetup."Start Date" := WorkDate();
        SalesByCustGrpChartSetup."Period Length" := SalesByCustGrpChartSetup."Period Length"::Week;
        SalesByCustGrpChartSetup.Insert();
    end;

    /// <summary>
    /// Returns the label text for the total sales measure.
    /// </summary>
    /// <returns>The total sales label text.</returns>
    procedure TotalSalesLCY(): Text
    begin
        exit(TotalSalesLCYTxt);
    end;
}

