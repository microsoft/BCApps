// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Analysis;

using Microsoft.Projects.Project.Job;
using System.Visualization;

codeunit 759 "Job Chart Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        Job: Record Job;
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        CL: array[16] of Decimal;
        PL: array[16] of Decimal;

        XAxisStringTxt: Label 'Project';
        TotalRevenueTxt: Label 'Total Revenue';
        TotalCostTxt: Label 'Total Cost';
        ProfitMarginTxt: Label 'Profit Margin';
        ActualTotalCostTxt: Label 'Actual Total Cost';
        BudgetTotalCostTxt: Label 'Budget Total Cost';
        CostVarianceTxt: Label 'Cost Variance';
        ActualTotalPriceTxt: Label 'Actual Total Price';
        BudgetTotalPriceTxt: Label 'Budget Total Price';
        PriceVarianceTxt: Label 'Price Variance';

    [Scope('OnPrem')]
    procedure CreateJobChart(var BusChartBuf: Record "Business Chart Buffer"; var TempJob: Record Job temporary; ChartType: Option Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel; JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price")
    begin
        CreateChart(BusChartBuf, TempJob, Enum::"Business Chart Type".FromInteger(ChartType), Enum::"Job Chart Type".FromInteger(JobChartType));
    end;

    procedure CreateChart(var BusChartBuf: Record "Business Chart Buffer"; var TempJob: Record Job temporary; ChartType: Enum "Business Chart Type"; JobChartType: Enum "Job Chart Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateChart(BusChartBuf, TempJob, ChartType, JobChartType, IsHandled);
        if IsHandled then
            exit;

        InitializeBusinessChart(BusChartBuf);
        SetJobRangeByMyJob(TempJob);
        if NothingToShow(TempJob) then
            exit;

        AddMeasures(BusChartBuf, ChartType, JobChartType);
        SetXAxis(BusChartBuf);
        SetJobChartValues(BusChartBuf, TempJob, JobChartType);
    end;

    procedure SetJobRangeByMyJob(var TempRangeJob: Record Job temporary)
    var
        MyJob: Record "My Job";
    begin
        TempRangeJob.DeleteAll();

        MyJob.SetRange("User ID", UserId);
        MyJob.SetRange("Exclude from Business Chart", false);
        if MyJob.FindSet() then
            repeat
                if Job.Get(MyJob."Job No.") then begin
                    TempRangeJob := Job;
                    TempRangeJob.Insert();
                end;
            until MyJob.Next() = 0;
    end;

    procedure DataPointClicked(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job)
    begin
        FindCurrentJob(BusChartBuf, RangeJob);
        DrillDownJobValue(RangeJob);
    end;

    local procedure FindCurrentJob(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job)
    begin
        RangeJob.FindSet();
        RangeJob.Next(BusChartBuf."Drill-Down X Index");
    end;

    local procedure DrillDownJobValue(var RangeJob: Record Job)
    begin
        PAGE.Run(PAGE::"Job Card", RangeJob);
    end;

    local procedure NothingToShow(var RangeJob: Record Job): Boolean
    begin
        exit(RangeJob.IsEmpty());
    end;

    local procedure InitializeBusinessChart(var BusChartBuf: Record "Business Chart Buffer")
    begin
        BusChartBuf.Initialize();
    end;

    local procedure AddMeasures(var BusChartBuf: Record "Business Chart Buffer"; ChartType: Enum "Business Chart Type"; JobChartType: Enum "Job Chart Type")
    begin
        case JobChartType of
            JobChartType::Profitability:
                begin
                    BusChartBuf.AddDecimalMeasure(TotalRevenueTxt, 1, ChartType);
                    BusChartBuf.AddDecimalMeasure(TotalCostTxt, 2, ChartType);
                    BusChartBuf.AddDecimalMeasure(ProfitMarginTxt, 3, ChartType);
                end;
            JobChartType::"Actual to Budget Cost":
                begin
                    BusChartBuf.AddDecimalMeasure(ActualTotalCostTxt, 1, ChartType);
                    BusChartBuf.AddDecimalMeasure(BudgetTotalCostTxt, 2, ChartType);
                    BusChartBuf.AddDecimalMeasure(CostVarianceTxt, 3, ChartType);
                end;
            JobChartType::"Actual to Budget Price":
                begin
                    BusChartBuf.AddDecimalMeasure(ActualTotalPriceTxt, 1, ChartType);
                    BusChartBuf.AddDecimalMeasure(BudgetTotalPriceTxt, 2, ChartType);
                    BusChartBuf.AddDecimalMeasure(PriceVarianceTxt, 3, ChartType);
                end;
        end;
    end;

    local procedure SetXAxis(var BusChartBuf: Record "Business Chart Buffer")
    begin
        BusChartBuf.SetXAxis(XAxisStringTxt, BusChartBuf."Data Type"::String);
    end;

    local procedure SetJobChartValues(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job; JobChartType: Enum "Job Chart Type")
    var
        Index: Integer;
        JobRevenue: Decimal;
        JobCost: Decimal;
        ActualCost: Decimal;
        BudgetCost: Decimal;
        ActualPrice: Decimal;
        BudgetPrice: Decimal;
    begin
        if RangeJob.FindSet() then
            repeat
                case JobChartType of
                    JobChartType::Profitability:
                        begin
                            CalculateJobRevenueAndCost(RangeJob, JobRevenue, JobCost);
                            SetJobChartValue(BusChartBuf, RangeJob, Index, JobRevenue, JobCost, JobChartType);
                        end;
                    JobChartType::"Actual to Budget Cost":
                        begin
                            CalculateJobCosts(RangeJob, ActualCost, BudgetCost);
                            SetJobChartValue(BusChartBuf, RangeJob, Index, ActualCost, BudgetCost, JobChartType);
                        end;
                    JobChartType::"Actual to Budget Price":
                        begin
                            CalculateJobPrices(RangeJob, ActualPrice, BudgetPrice);
                            SetJobChartValue(BusChartBuf, RangeJob, Index, ActualPrice, BudgetPrice, JobChartType);
                        end;
                end;
            until RangeJob.Next() = 0;
    end;

    local procedure SetJobChartValue(var BusChartBuf: Record "Business Chart Buffer"; var RangeJob: Record Job; var Index: Integer; Value1: Decimal; Value2: Decimal; JobChartType: Enum "Job Chart Type")
    begin
        BusChartBuf.AddColumn(RangeJob."No.");
        BusChartBuf.SetValueByIndex(0, Index, Value1);
        BusChartBuf.SetValueByIndex(1, Index, Value2);
        if JobChartType = JobChartType::Profitability then
            BusChartBuf.SetValueByIndex(2, Index, (Value1 - Value2));
        if (JobChartType = JobChartType::"Actual to Budget Cost") or (JobChartType = JobChartType::"Actual to Budget Price") then
            BusChartBuf.SetValueByIndex(2, Index, (Value2 - Value1));
        Index += 1;
    end;

    procedure CalculateJobRevenueAndCost(var RangeJob: Record Job; var JobRevenue: Decimal; var JobCost: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        JobRevenue := PL[16];
        JobCost := CL[8];
    end;

    procedure CalculateJobCosts(var RangeJob: Record Job; var ActualCost: Decimal; var BudgetCost: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        ActualCost := CL[8];
        BudgetCost := CL[4];
    end;

    procedure CalculateJobPrices(var RangeJob: Record Job; var ActualPrice: Decimal; var BudgetPrice: Decimal)
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(RangeJob);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        ActualPrice := PL[16];
        BudgetPrice := PL[4];
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateChart(var BusChartBuf: Record "Business Chart Buffer"; var TempJob: Record Job temporary; ChartType: Enum "Business Chart Type"; JobChartType: Enum "Job Chart Type"; var IsHandled: Boolean)
    begin
    end;
}

