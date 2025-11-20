// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Visualization;

codeunit 1326 "Top Five Customers Chart Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CustomerXCaptionTxt: Label 'Customer Name';
        SalesLCYYCaptionTxt: Label 'Sales (LCY)';
        AllOtherCustomersTxt: Label 'All Other Customers';
        CustomerNameNoLbl: Label '%1 - %2', Locked = true;
        CustomerNo: array[5] of Code[20];

    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        GLSetup: Record "General Ledger Setup";
        ColumnIndex: Integer;
        CustomerName: array[11] of Text[100];
        SalesLCY: array[11] of Decimal;
    begin
        BusChartBuf.Initialize();
        if GLSetup.Get() then;
        BusChartBuf.AddDecimalMeasure(SalesLCYYCaptionTxt, 1, BusChartBuf."Chart Type"::Doughnut);
        BusChartBuf.SetXAxis(CustomerXCaptionTxt, BusChartBuf."Data Type"::String);
        CalcTopSalesCustomers(CustomerName, SalesLCY);
        for ColumnIndex := 1 to 6 do begin
            if SalesLCY[ColumnIndex] = 0 then
                exit;
            BusChartBuf.AddColumn(CustomerName[ColumnIndex]);
            BusChartBuf.SetValueByIndex(0, ColumnIndex - 1, SalesLCY[ColumnIndex]);
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        CustomerName: Variant;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", CustomerName);
        // drill down only for top 5 customers
        // for the 6th column "all other customers", it drills down to customer list of all other customers
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" < 5) then
            DrillDownCust(CustomerNo[BusChartBuf."Drill-Down X Index" + 1]);
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" = 5) then
            DrillDownOtherCustList();
    end;

    local procedure CalcTopSalesCustomers(var CustomerName: array[6] of Text[100]; var SalesLCY: array[6] of Decimal)
    var
        TopCustomersBySalesBuffer: Record "Top Customers By Sales Buffer";
        TopCustomersBySalesJob: Codeunit "Top Customers By Sales Job";
        ChartManagement: Codeunit "Chart Management";
        ColumnIndex: Integer;
        OtherCustomersSalesLCY: Decimal;
    begin
        if TopCustomersBySalesBuffer.IsEmpty() then
            TopCustomersBySalesJob.UpdateCustomerTopList();

        if TopCustomersBySalesBuffer.FindSet() then begin
            repeat
                ColumnIndex += 1;
                if ColumnIndex <= 5 then begin
                    CustomerName[TopCustomersBySalesBuffer.Ranking] :=
                        CopyStr(StrSubstNo(CustomerNameNoLbl, TopCustomersBySalesBuffer.CustomerNo, TopCustomersBySalesBuffer.CustomerName),
                            1, MaxStrLen(CustomerName[TopCustomersBySalesBuffer.Ranking]));
                    SalesLCY[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.SalesLCY;
                    CustomerNo[TopCustomersBySalesBuffer.Ranking] := TopCustomersBySalesBuffer.CustomerNo
                end else
                    OtherCustomersSalesLCY += TopCustomersBySalesBuffer.SalesLCY;
            until TopCustomersBySalesBuffer.Next() = 0;

            if OtherCustomersSalesLCY <> 0 then begin
                CustomerName[6] := AllOtherCustomersTxt;
                SalesLCY[6] := OtherCustomersSalesLCY
            end;

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
        Customer.SetFilter("No.", GetFilterToExcludeTopFiveCustomers());
        Customer.SetCurrentKey(Name);
        Customer.Ascending(true);
        Page.Run(Page::"Customer List", Customer);
    end;

    local procedure GetFilterToExcludeTopFiveCustomers(): Text
    var
        CustomerCounter: Integer;
        FilterToExcludeTopFiveCustomers: Text;
    begin
        for CustomerCounter := 1 to 5 do
            if CustomerCounter = 1 then
                FilterToExcludeTopFiveCustomers := StrSubstNo('<>%1', CustomerNo[CustomerCounter])
            else
                FilterToExcludeTopFiveCustomers += StrSubstNo('&<>%1', CustomerNo[CustomerCounter]);
        exit(FilterToExcludeTopFiveCustomers);
    end;
}
