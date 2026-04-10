// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.CRM.Opportunity;
using Microsoft.Sales.Analysis;

codeunit 6309 "PBI Sales Pipeline Chart Calc."
{

    trigger OnRun()
    begin
    end;

    var
        SalesPipelineChartMgt: Codeunit "Sales Pipeline Chart Mgt.";

    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    var
        TempSalesCycleStage: Record "Sales Cycle Stage" temporary;
        SalesCycle: Record "Sales Cycle";
    begin
        if SalesCycle.FindSet() then
            repeat
                SalesPipelineChartMgt.InsertTempSalesCycleStage(TempSalesCycleStage, SalesCycle);
                if TempSalesCycleStage.FindSet() then
                    repeat
                        InsertToBuffer(TempPowerBIChartBuffer, TempSalesCycleStage);
                    until TempSalesCycleStage.Next() = 0;
            until SalesCycle.Next() = 0;
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; TempSalesCycleStage: Record "Sales Cycle Stage" temporary)
    begin
        if TempPowerBIChartBuffer.FindLast() then
            TempPowerBIChartBuffer.ID += 1
        else
            TempPowerBIChartBuffer.ID := 1;
        TempPowerBIChartBuffer."Row No." := Format(TempSalesCycleStage.Stage);
        TempPowerBIChartBuffer.Value := SalesPipelineChartMgt.GetOppEntryCount(TempSalesCycleStage."Sales Cycle Code", TempSalesCycleStage.Stage);
        TempPowerBIChartBuffer."Measure Name" := TempSalesCycleStage.Description;
        TempPowerBIChartBuffer."Measure No." := TempSalesCycleStage."Sales Cycle Code";
        TempPowerBIChartBuffer.Insert();
    end;
}

