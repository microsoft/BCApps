// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using System.Visualization;

codeunit 1316 "Top Ten Customers Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CustomerXCaptionTxt: Label 'Customer Name';
        SalesLCYYCaptionTxt: Label 'Sales (LCY)';
        CustomerNameNoLbl: Label '%1 - %2', Locked = true;
        CustomerNo: array[10] of Code[20];

    [Scope('OnPrem')]
    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        ColumnIndex: Integer;
        CustomerName: array[11] of Text[100];
        SalesLCY: array[11] of Decimal;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.AddDecimalMeasure(SalesLCYYCaptionTxt, 1, BusChartBuf."Chart Type"::StackedColumn);
        BusChartBuf.SetXAxis(CustomerXCaptionTxt, BusChartBuf."Data Type"::String);
        CalcTopTenSalesCustomers(CustomerName, SalesLCY);
        for ColumnIndex := 1 to 11 do begin
            if SalesLCY[ColumnIndex] = 0 then
                exit;
            BusChartBuf.AddColumn(CustomerName[ColumnIndex]);
            BusChartBuf.SetValueByIndex(0, ColumnIndex - 1, SalesLCY[ColumnIndex]);
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        CustomerName: Variant;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", CustomerName);
        // drill down only for top 10 customers
        // for the 11th column "all other customers", it drills down to customer list of all other customers
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" < 10) then
            DrillDownCust(CustomerNo[BusChartBuf."Drill-Down X Index" + 1]);
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" = 10) then
            DrillDownOtherCustList();
    end;

    local procedure CalcTopTenSalesCustomers(var CustomerName: array[11] of Text[100]; var SalesLCY: array[11] of Decimal)
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TopCustomersBySalesJob: Codeunit "Top Customers By Sales Job";
        ChartManagement: Codeunit "Chart Management";
    begin
        if TopCustomersBySalesBuffer.IsEmpty() then
            TopCustomersBySalesJob.UpdateCustomerTopList();

        if TopCustomersBySalesBuffer.FindSet() then begin
            repeat
                CustomerName[TopCustomersBySalesBuffer.Ranking] :=
                        CopyStr(StrSubstNo(CustomerNameNoLbl, TopCustomersBySalesBuffer.CustomerNo, TopCustomersBySalesBuffer.CustomerName),
                            1, MaxStrLen(CustomerName[TopCustomersBySalesBuffer.Ranking]));
                SalesLCY[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.SalesLCY;
                if TopCustomersBySalesBuffer.Ranking <= 10 then
                    CustomerNo[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.CustomerNo
            until TopCustomersBySalesBuffer.Next() = 0;
            ChartManagement.ScheduleTopCustomerListRefreshTask()
        end;
    end;

    local procedure DrillDownCust(DrillDownCustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(DrillDownCustomerNo);
        Page.Run(Page::"Customer Card", Customer);
    end;

    local procedure DrillDownOtherCustList()
    var
        Customer: Record Customer;
    begin
        Customer.SetFilter("No.", GetFilterToExcludeTopTenCustomers());
        Customer.SetCurrentKey(Name);
        Customer.Ascending(true);
        Page.Run(Page::"Customer List", Customer);
    end;

    local procedure GetFilterToExcludeTopTenCustomers(): Text
    var
        CustomerCounter: Integer;
        FilterToExcludeTopTenCustomers: Text;
    begin
        for CustomerCounter := 1 to 10 do
            if CustomerCounter = 1 then
                FilterToExcludeTopTenCustomers := StrSubstNo('<>%1', CustomerNo[CustomerCounter])
            else
                FilterToExcludeTopTenCustomers += StrSubstNo('&<>%1', CustomerNo[CustomerCounter]);
        exit(FilterToExcludeTopTenCustomers);
    end;
}
