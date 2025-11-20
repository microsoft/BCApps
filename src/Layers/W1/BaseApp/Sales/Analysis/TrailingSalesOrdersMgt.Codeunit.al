// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Document;
using System.Visualization;

codeunit 760 "Trailing Sales Orders Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TrailingSalesOrdersSetup: Record "Trailing Sales Orders Setup";
        SalesHeader: Record "Sales Header";

    procedure OnOpenPage(var TrailingSalesOrdersSetup: Record "Trailing Sales Orders Setup")
    begin
        if not TrailingSalesOrdersSetup.Get(UserId) then begin
            TrailingSalesOrdersSetup.LockTable();
            TrailingSalesOrdersSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(TrailingSalesOrdersSetup."User ID"));
            TrailingSalesOrdersSetup."Use Work Date as Base" := true;
            TrailingSalesOrdersSetup."Period Length" := TrailingSalesOrdersSetup."Period Length"::Month;
            TrailingSalesOrdersSetup."Value to Calculate" := TrailingSalesOrdersSetup."Value to Calculate"::"No. of Orders";
            TrailingSalesOrdersSetup."Chart Type" := TrailingSalesOrdersSetup."Chart Type"::"Stacked Column";
            TrailingSalesOrdersSetup.Insert();
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        SalesHeader: Record "Sales Header";
        ToDate: Date;
        Measure: Integer;
        IsHandled: Boolean;
    begin
        Measure := BusChartBuf."Drill-Down Measure Index";
        if (Measure < 0) or (Measure > 3) then
            exit;
        TrailingSalesOrdersSetup.Get(UserId);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            SalesHeader.SetFilter("Shipment Date", '<%1', TrailingSalesOrdersSetup.GetStartDate());
        if Evaluate(SalesHeader.Status, BusChartBuf.GetMeasureValueString(Measure), 9) then
            SalesHeader.SetRange(Status, SalesHeader.Status);

        ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
        SalesHeader.SetRange("Document Date", 0D, ToDate);

        IsHandled := false;
        OnDrillDownOnBeforeRunPage(SalesHeader, IsHandled);
        if not IsHandled then
            PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;

    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer")
    var
        ChartToStatusMap: array[4] of Integer;
        ToDate: array[5] of Date;
        FromDate: array[5] of Date;
        Value: Decimal;
        TotalValue: Decimal;
        ColumnNo: Integer;
        SalesHeaderStatus: Integer;
    begin
        TrailingSalesOrdersSetup.Get(UserId);
        BusChartBuf.Initialize();
        BusChartBuf."Period Length" := TrailingSalesOrdersSetup."Period Length";
        BusChartBuf.SetPeriodXAxis();

        CreateMap(ChartToStatusMap);
        for SalesHeaderStatus := 1 to ArrayLen(ChartToStatusMap) do begin
            SalesHeader.Status := "Sales Document Status".FromInteger(ChartToStatusMap[SalesHeaderStatus]);
            BusChartBuf.AddDecimalMeasure(Format(SalesHeader.Status), SalesHeader.Status, TrailingSalesOrdersSetup.GetBusinessChartType());
        end;

        if CalcPeriods(FromDate, ToDate, BusChartBuf) then begin
            BusChartBuf.AddPeriods(ToDate[1], ToDate[ArrayLen(ToDate)]);

            for SalesHeaderStatus := 1 to ArrayLen(ChartToStatusMap) do begin
                TotalValue := 0;
                for ColumnNo := 1 to ArrayLen(ToDate) do begin
                    Value := GetSalesOrderValue(ChartToStatusMap[SalesHeaderStatus], FromDate[ColumnNo], ToDate[ColumnNo]);
                    if ColumnNo = 1 then
                        TotalValue := Value
                    else
                        TotalValue += Value;
                    BusChartBuf.SetValueByIndex(SalesHeaderStatus - 1, ColumnNo - 1, TotalValue);
                end;
            end;
        end;
    end;

    local procedure CalcPeriods(var FromDate: array[5] of Date; var ToDate: array[5] of Date; var BusChartBuf: Record "Business Chart Buffer"): Boolean
    var
        MaxPeriodNo: Integer;
        i: Integer;
    begin
        MaxPeriodNo := ArrayLen(ToDate);
        ToDate[MaxPeriodNo] := TrailingSalesOrdersSetup.GetStartDate();
        if ToDate[MaxPeriodNo] = 0D then
            exit(false);
        for i := MaxPeriodNo downto 1 do
            if i > 1 then begin
                FromDate[i] := BusChartBuf.CalcFromDate(ToDate[i]);
                ToDate[i - 1] := FromDate[i] - 1;
            end else
                FromDate[i] := 0D;
        exit(true);
    end;

    local procedure GetSalesOrderValue(Status: Option; FromDate: Date; ToDate: Date): Decimal
    begin
        if TrailingSalesOrdersSetup."Value to Calculate" = TrailingSalesOrdersSetup."Value to Calculate"::"No. of Orders" then
            exit(GetSalesOrderCount(Status, FromDate, ToDate));
        exit(GetSalesOrderAmount(Status, FromDate, ToDate));
    end;

    local procedure GetSalesOrderAmount(Status: Option; FromDate: Date; ToDate: Date) Result: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        TrailingSalesOrderQry: Query "Trailing Sales Order Qry";
        Amount: Decimal;
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesOrderAmount(Status, FromDate, ToDate, Result, IsHandled, TrailingSalesOrdersSetup);
        if IsHandled then
            exit(Result);

        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            TrailingSalesOrderQry.SetFilter(ShipmentDate, '<%1', TrailingSalesOrdersSetup.GetStartDate());

        TrailingSalesOrderQry.SetRange(Status, Status);
        TrailingSalesOrderQry.SetRange(DocumentDate, FromDate, ToDate);
        TrailingSalesOrderQry.Open();
        while TrailingSalesOrderQry.Read() do begin
            if TrailingSalesOrderQry.CurrencyCode = '' then
                Amount := TrailingSalesOrderQry.Amount
            else
                Amount := Round(TrailingSalesOrderQry.Amount / CurrExchRate.ExchangeRate(Today, TrailingSalesOrderQry.CurrencyCode));
            TotalAmount := TotalAmount + Amount;
        end;
        exit(TotalAmount);
    end;

    local procedure GetSalesOrderCount(Status: Option; FromDate: Date; ToDate: Date): Decimal
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if TrailingSalesOrdersSetup."Show Orders" = TrailingSalesOrdersSetup."Show Orders"::"Delayed Orders" then
            SalesHeader.SetFilter("Shipment Date", '<%1', TrailingSalesOrdersSetup.GetStartDate())
        else
            SalesHeader.SetRange("Shipment Date");
        SalesHeader.SetRange(Status, Status);
        SalesHeader.SetRange("Document Date", FromDate, ToDate);
        OnGetSalesOrderCountOnAfterSetFilters(SalesHeader);
        exit(SalesHeader.Count);
    end;

    procedure CreateMap(var Map: array[4] of Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        Map[1] := SalesHeader.Status::Released.AsInteger();
        Map[2] := SalesHeader.Status::"Pending Prepayment".AsInteger();
        Map[3] := SalesHeader.Status::"Pending Approval".AsInteger();
        Map[4] := SalesHeader.Status::Open.AsInteger();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesOrderAmount(Status: Option; FromDate: Date; ToDate: Date; var Result: Decimal; var IsHandled: Boolean; TrailingSalesOrdersSetup: Record "Trailing Sales Orders Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesOrderCountOnAfterSetFilters(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownOnBeforeRunPage(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

