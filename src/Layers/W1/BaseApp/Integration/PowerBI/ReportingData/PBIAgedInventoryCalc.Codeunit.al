// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Inventory.Analysis;
using System.Environment;
using System.Visualization;

codeunit 6307 "PBI Aged Inventory Calc."
{

    trigger OnRun()
    begin
    end;

    var
        TempBusinessChartBuffer: Record "Business Chart Buffer" temporary;
        AgedInventoryChartMgt: Codeunit "Aged Inventory Chart Mgt.";

    [Scope('OnPrem')]
    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    var
        SelectedChartDefinition: Record "Chart Definition";
        ChartManagement: Codeunit "Chart Management";
        i: Integer;
        DummyInvtValue: array[5] of Decimal;
        PeriodStartDate: array[6] of Date;
    begin
        for i := 0 to 4 do begin
            Clear(DummyInvtValue);
            ChartManagement.SetPeriodLength(SelectedChartDefinition, TempBusinessChartBuffer, i, false);
            CalcPeriodStartDates(PeriodStartDate, AgedInventoryChartMgt.GetPeriodLengthInDays(TempBusinessChartBuffer));
            AgedInventoryChartMgt.CalcInventoryValuePerAge(DummyInvtValue, PeriodStartDate);
            InsertToBuffer(TempPowerBIChartBuffer, DummyInvtValue);
        end;
    end;

    local procedure CalcPeriodStartDates(var PeriodStartDate: array[6] of Date; PeriodLength: Integer)
    var
        LogInManagement: Codeunit LogInManagement;
        I: Integer;
    begin
        PeriodStartDate[6] := LogInManagement.GetDefaultWorkDate();
        PeriodStartDate[1] := 0D;
        for I := 2 to 5 do
            PeriodStartDate[I] := CalcDate('<-' + Format((6 - I) * PeriodLength) + 'D>', PeriodStartDate[6]);
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; pInvtValue: array[5] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 5 do begin
            if TempPowerBIChartBuffer.FindLast() then
                TempPowerBIChartBuffer.ID += 1
            else
                TempPowerBIChartBuffer.ID := 1;
            TempPowerBIChartBuffer.Value := pInvtValue[i];
            TempPowerBIChartBuffer."Period Type" := TempBusinessChartBuffer."Period Length";
            TempPowerBIChartBuffer.Date := AddChartColumns(TempBusinessChartBuffer, -i);
            TempPowerBIChartBuffer."Period Type Sorting" := TempPowerBIChartBuffer."Period Type";
            TempPowerBIChartBuffer.Insert();
        end
    end;

    local procedure AddChartColumns(var BusChartBuf: Record "Business Chart Buffer"; I: Integer): Text[30]
    var
        AgedInventoryChartMgt: Codeunit "Aged Inventory Chart Mgt.";
        PeriodLengthOnXAxis: Integer;
        XAxisValueTxt: Text[30];
        LastXAxisValueTxt: Text[30];
        J: Integer;
        Value1: Integer;
        Value2: Integer;
    begin
        I := I + 5;

        PeriodLengthOnXAxis := AgedInventoryChartMgt.GetPeriodLengthInDays(BusChartBuf);
        if PeriodLengthOnXAxis = 365 then begin
            PeriodLengthOnXAxis := 1;
            XAxisValueTxt := AgedInventoryChartMgt.FromToYearsTxt();
            LastXAxisValueTxt := AgedInventoryChartMgt.OverYearsTxt();
        end else begin
            XAxisValueTxt := AgedInventoryChartMgt.FromToDaysTxt();
            LastXAxisValueTxt := AgedInventoryChartMgt.OverDaysTxt();
        end;
        if I < 4 then begin
            J := I + 1;
            Value1 := I * PeriodLengthOnXAxis;
            Value2 := J * PeriodLengthOnXAxis;
            exit(StrSubstNo(XAxisValueTxt, Value1, Value2));
            // X-Axis value
        end;
        exit(StrSubstNo(LastXAxisValueTxt, Format(4 * PeriodLengthOnXAxis)));  // X-Axis value
    end;
}

