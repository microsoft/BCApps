// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.Purchases.Vendor;
using System.Visualization;

codeunit 9095 "Purch. by Vend.Grp. Chart Mgt."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PurchByVendGrpChartSetup: Record "Purch. by Vend.Grp.Chart Setup";
        TotalPurchLCYTxt: Label 'Total Purchases (LCY)';
        DateExpressionTok: Label '<1D>', Locked = true;

    /// <summary>
    /// Update the chart with the purchase by vendor group data.
    /// </summary>
    /// <param name="BusChartBuf">Return value: Business Chart Buffer record</param>
    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        NoOfPeriods: Integer;
        ToDate: Date;
        FromDate: Date;
        PeriodNo: Integer;
    begin
        GetChartSetupForCurrentUser();

        NoOfPeriods := GetNumberOfPeriods();
        BusChartBuf.Initialize();
        BusChartBuf."Period Length" := PurchByVendGrpChartSetup."Period Length";
        BusChartBuf."Period Filter Start Date" := PurchByVendGrpChartSetup."Start Date";

        FromDate := BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date");
        for PeriodNo := 1 to NoOfPeriods do begin
            ToDate := BusChartBuf.CalcToDate(FromDate);
            FromDate := CalcDate(DateExpressionTok, ToDate);
        end;
        BusChartBuf."Period Filter End Date" := ToDate;

        BusChartBuf.SetPeriodXAxis();
        BusChartBuf.AddPeriods(BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date"), ToDate);

        CalcVendorPurchases(BusChartBuf, NoOfPeriods);
    end;

    /// <summary>
    /// Drill down to the vendor list page based on the selected vendor group.
    /// </summary>
    /// <param name="BusChartBuf">Return value: Business Chart Buffer record</param>
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        Vendor: Record Vendor;
        ToDate: Date;
        FromDate: Date;
        MeasureValueString: Text;
    begin
        GetChartSetupForCurrentUser();

        BusChartBuf."Period Length" := PurchByVendGrpChartSetup."Period Length";
        ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
        FromDate := BusChartBuf.CalcFromDate(ToDate);
        MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");

        if MeasureValueString <> '' then
            Vendor.SetRange("Vendor Posting Group", MeasureValueString);
        Vendor.SetRange("Date Filter", FromDate, ToDate);
        Page.Run(Page::"Vendor List", Vendor);
    end;

    local procedure CalcVendorPurchases(var BusChartBuf: Record "Business Chart Buffer"; NoOfPeriods: Decimal)
    var
        PurchaseByVendorGroup: Query "Purchase by Vendor Group";
        TotalSalesValue: Decimal;
        FromDate: Date;
        ToDate: Date;
        PeriodNo: Integer;
    begin
        BusChartBuf.AddDecimalMeasure(TotalPurchLCYTxt, '', BusChartBuf."Chart Type"::Line);

        FromDate := BusChartBuf.CalcFromDate(BusChartBuf."Period Filter Start Date");
        for PeriodNo := 1 to NoOfPeriods do begin
            ToDate := BusChartBuf.CalcToDate(FromDate);
            TotalSalesValue := 0;

            PurchaseByVendorGroup.SetRange(Date_Filter, FromDate, ToDate);
            PurchaseByVendorGroup.Open();

            if PurchaseByVendorGroup.Read() then
                repeat
                    if PeriodNo = 1 then
                        BusChartBuf.AddDecimalMeasure(PurchaseByVendorGroup.Code, PurchaseByVendorGroup.Code, BusChartBuf."Chart Type"::Column);
                    BusChartBuf.SetValue(PurchaseByVendorGroup.Code, PeriodNo - 1, PurchaseByVendorGroup.Purchases__LCY_);

                    TotalSalesValue += PurchaseByVendorGroup.Purchases__LCY_;
                until not PurchaseByVendorGroup.Read()
            else begin
                BusChartBuf.Initialize();
                exit;
            end;

            BusChartBuf.SetValue(TotalPurchLCYTxt, PeriodNo - 1, TotalSalesValue);
            FromDate := CalcDate(DateExpressionTok, ToDate);
        end;
    end;

    local procedure GetChartSetupForCurrentUser()
    begin
        if PurchByVendGrpChartSetup.Get(UserId) then
            exit;
        PurchByVendGrpChartSetup.Init();
        PurchByVendGrpChartSetup."User ID" := UserId();
        PurchByVendGrpChartSetup."Start Date" := WorkDate();
        PurchByVendGrpChartSetup."Period Length" := PurchByVendGrpChartSetup."Period Length"::Week;
        PurchByVendGrpChartSetup.Insert(true);
    end;

    local procedure GetNumberOfPeriods(): Integer
    begin
        exit(5);
    end;

}